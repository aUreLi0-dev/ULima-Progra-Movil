class EvaluationComponent {
  final int id;
  final String nombre;
  final String sigla;
  final double peso;
  final String? tipo;

  EvaluationComponent({
    required this.id,
    required this.nombre,
    required this.sigla,
    required this.peso,
    this.tipo,
  });

  factory EvaluationComponent.fromJson(Map<String, dynamic> json) {
    return EvaluationComponent(
      id: json['assessment_id'] is int
          ? json['assessment_id'] as int
          : int.tryParse(json['assessment_id'].toString()) ?? 0,
      nombre: json['assessment_name'] as String? ?? json['nombre'] as String? ?? '',
      sigla: json['assessment_code'] as String? ?? json['sigla'] as String? ?? '',
      peso: (json['weight'] as num?)?.toDouble() ?? (json['peso'] as num?)?.toDouble() ?? 0.0,
      tipo: json['assessment_type'] as String? ?? json['tipo'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assessment_id': id,
      'assessment_name': nombre,
      'assessment_code': sigla,
      'weight': peso,
      'assessment_type': tipo,
    };
  }
}

class CourseSyllabus {
  final String cursoId;
  final String cursoNombre;
  final List<EvaluationComponent> evaluaciones;

  CourseSyllabus({
    required this.cursoId,
    required this.cursoNombre,
    required this.evaluaciones,
  });

  double get pesoTotal => evaluaciones.fold(0, (sum, eval) => sum + eval.peso);

  factory CourseSyllabus.fromJson(Map<String, dynamic> json) {
    final evaluacionesList = (json['assesments'] as List<dynamic>? ?? [])
        .map((eval) => EvaluationComponent.fromJson(eval as Map<String, dynamic>))
        .toList();
    return CourseSyllabus(
      cursoId: json['cursoId']?.toString() ?? json['course']?['id']?.toString() ?? '',
      cursoNombre: json['cursoNombre'] as String? ?? json['course']?['name'] as String? ?? '',
      evaluaciones: evaluacionesList,
    );
  }
}
