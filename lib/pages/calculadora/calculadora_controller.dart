import 'package:get/get.dart';
import '../../models/evaluation_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class CalculadoraController extends GetxController {
  final cursos = <Map<String, dynamic>>[].obs;
  final syllabusData = <String, CourseSyllabus>{}.obs;
  final cargando = false.obs;

  @override
  void onInit() {
    super.onInit();
    _cargarCursos();
  }

  Future<void> _cargarCursos() async {
    cargando.value = true;
    try {
      final user = AuthService.to.currentUser;
      if (user == null) return;

      final api = ApiService.to;
      final response = await api.get('/api/v1/calculator/student/${user.id}/courses');

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final coursesList = data['courses'] as List<dynamic>? ?? [];

        cursos.value = await Future.wait(coursesList.map((raw) async {
          final c = raw as Map<String, dynamic>;
          final courseData = c['course'] as Map<String, dynamic>? ?? {};
          final enrollmentId = c['enrollment_id'] as int? ?? 0;

          final detailResponse = await api.get('/api/v1/calculator/enrollment/$enrollmentId');
          List<Map<String, dynamic>> notas = [];
          if (detailResponse.success && detailResponse.data != null) {
            final detail = detailResponse.data as Map<String, dynamic>;
            final assesments = detail['assesments'] as List<dynamic>? ?? [];

            final syllabus = CourseSyllabus.fromJson(detail);
            final courseId = courseData['id']?.toString() ?? '';
            if (courseId.isNotEmpty) {
              syllabusData[syllabus.cursoId] = syllabus;
            }

              for (final a in assesments) {
                final aMap = a as Map<String, dynamic>;
                final value = aMap['value'];
                if (value != null) {
                  notas.add({
                    'simulated_grade_id': aMap['simulated_grade_id'],
                    'titulo': aMap['assessment_name'] as String? ?? '',
                    'peso': (aMap['weight'] as num).toInt(),
                    'valor': (value as num).toDouble(),
                    'assessment_id': aMap['assessment_id'],
                  });
                }
              }
          }

          return {
            'enrollment_id': enrollmentId,
            'course_id': courseData['id'],
            'nombre': courseData['name'] as String? ?? '',
            'ciclo': c['academic_period_code'] as String? ?? '',
            'seccion': c['section_code'] as String? ?? '',
            'weighted_average': c['weighted_average'],
            'total_weight': c['total_weight'],
            'notas': notas.obs,
          };
        }).toList());
      }
    } catch (e) {
      print('Error al cargar cursos: $e');
    } finally {
      cargando.value = false;
    }
  }

  double calcularPromedio(List notas) {
    if (notas.isEmpty) return 0.0;
    double suma = 0;
    for (var n in notas) {
      suma += (n['valor'] * (n['peso'] / 100));
    }
    return suma;
  }

  double sumaPesos(List notas) {
    return notas.fold(0, (sum, item) => sum + (item['peso'] as num).toDouble());
  }

  Future<void> agregarNota(int cursoIndex, String titulo, int peso, double valor, int assessmentId) async {
    if (cursoIndex < 0 || cursoIndex >= cursos.length) return;

    final enrollmentId = cursos[cursoIndex]['enrollment_id'] as int? ?? 0;
    if (enrollmentId == 0) return;

    final api = ApiService.to;
    final response = await api.post('/api/v1/calculator/simulated-grades', body: {
      'enrollment_id': enrollmentId,
      'assessment_id': assessmentId,
      'value': valor,
    });

    if (response.success) {
      final notas = cursos[cursoIndex]['notas'] as RxList;
      final scoreData = response.data as Map<String, dynamic>?;
      notas.add({
        'simulated_grade_id': scoreData?['id'],
        'titulo': titulo,
        'peso': peso,
        'valor': valor,
        'assessment_id': assessmentId,
      });
      cursos.refresh();
    }
  }

  Future<void> eliminarNota(int cursoIndex, int notaIndex) async {
    if (cursoIndex < 0 || cursoIndex >= cursos.length) return;

    final notas = cursos[cursoIndex]['notas'] as RxList;
    if (notaIndex < 0 || notaIndex >= notas.length) return;

    final enrollmentId = cursos[cursoIndex]['enrollment_id'] as int? ?? 0;
    final nota = notas[notaIndex] as Map<String, dynamic>;
    final assessmentId = nota['assessment_id'] as int? ?? 0;

    if (enrollmentId > 0 && assessmentId > 0) {
      final api = ApiService.to;
      await api.post('/api/v1/calculator/simulated-grades', body: {
        'enrollment_id': enrollmentId,
        'assessment_id': assessmentId,
        'value': null,
      });
    }

    notas.removeAt(notaIndex);
    cursos.refresh();
  }

  CourseSyllabus? getSyllabusForCourse(int cursoIndex) {
    if (cursoIndex >= 0 && cursoIndex < cursos.length) {
      final courseId = cursos[cursoIndex]['course_id']?.toString() ?? '';
      if (courseId.isNotEmpty && syllabusData.containsKey(courseId)) {
        return syllabusData[courseId];
      }
    }
    return null;
  }

  List<EvaluationComponent> getEvaluationsForCourse(int cursoIndex) {
    final syllabus = getSyllabusForCourse(cursoIndex);
    return syllabus?.evaluaciones ?? [];
  }

  bool hasSyllabusData(int cursoIndex) {
    if (cursoIndex >= 0 && cursoIndex < cursos.length) {
      final courseId = cursos[cursoIndex]['course_id']?.toString() ?? '';
      return courseId.isNotEmpty && syllabusData.containsKey(courseId);
    }
    return false;
  }

  List<int> getRegisteredAssessmentIds(int cursoIndex) {
    if (cursoIndex >= 0 && cursoIndex < cursos.length) {
      final notas = cursos[cursoIndex]['notas'] as List?;
      return (notas ?? [])
          .map((nota) => nota['assessment_id'] as int? ?? 0)
          .where((id) => id > 0)
          .toList();
    }
    return [];
  }

  List<EvaluationComponent> getAvailableEvaluations(int cursoIndex) {
    final allEvaluations = getEvaluationsForCourse(cursoIndex);
    final registeredIds = getRegisteredAssessmentIds(cursoIndex);
    return allEvaluations
        .where((eval) => !registeredIds.contains(eval.id))
        .toList();
  }
}
