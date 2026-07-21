import 'package:get/get.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class SetupCarreraController extends GetxController {
  final carreras = <Map<String, dynamic>>[].obs;
  final especialidadesDisponibles = <Map<String, dynamic>>[].obs;
  final cargandoCarreras = false.obs;
  final cargandoEspecialidades = false.obs;

  final selectedCarreraId = RxnInt();
  final selectedEspecialidadIds = <int>{}.obs;
  final errorMessage = RxnString();
  final saving = false.obs;

  AuthService get _auth => AuthService.to;

  @override
  void onInit() {
    super.onInit();
    _cargarCarreras();
  }

  Future<void> _cargarCarreras() async {
    cargandoCarreras.value = true;
    try {
      final api = ApiService.to;
      final response = await api.get('/api/v1/careers');
      if (response.success && response.data != null) {
        carreras.value = List<Map<String, dynamic>>.from(response.data as List);
      }
    } finally {
      cargandoCarreras.value = false;
    }
  }

  void onCarreraChanged(int? carreraId) {
    selectedCarreraId.value = carreraId;
    selectedEspecialidadIds.clear();
    if (carreraId != null) {
      _cargarEspecialidades(carreraId);
    }
  }

  Future<void> _cargarEspecialidades(int carreraId) async {
    cargandoEspecialidades.value = true;
    try {
      final api = ApiService.to;
      final response = await api.get('/api/v1/specialties', queryParams: {'career_id': carreraId.toString()});
      if (response.success && response.data != null) {
        especialidadesDisponibles.value = List<Map<String, dynamic>>.from(response.data as List);
      }
    } finally {
      cargandoEspecialidades.value = false;
    }
  }

  void toggleEspecialidad(int id) {
    if (selectedEspecialidadIds.contains(id)) {
      selectedEspecialidadIds.remove(id);
    } else {
      selectedEspecialidadIds.add(id);
    }
  }

  Future<void> finish() async {
    if (selectedCarreraId.value == null) {
      errorMessage.value = 'Selecciona tu carrera para continuar.';
      return;
    }
    errorMessage.value = null;
    saving.value = true;

    final error = await _auth.completeSetup(
      careerId: selectedCarreraId.value!,
      specialtyIds: selectedEspecialidadIds.toList(),
    );

    saving.value = false;

    if (error != null) {
      errorMessage.value = error;
      return;
    }

    Get.offAllNamed('/home');
  }
}
