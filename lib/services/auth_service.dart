import 'package:get/get.dart';

import '../models/user_model.dart';
import 'api_service.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
  final RxBool _loading = false.obs;

  UserModel? get currentUser => _currentUser.value;
  bool get isLoggedIn => _currentUser.value != null;
  bool get isLoading => _loading.value;

  Future<String?> login({required String code, required String password}) async {
    _loading.value = true;
    try {
      final api = ApiService.to;
      final response = await api.post('/api/sign-in', body: {
        'code': code.trim(),
        'password': password,
      });

      if (!response.success) {
        return response.error ?? response.message ?? 'Error al iniciar sesión';
      }

      final data = response.data as Map<String, dynamic>?;
      if (data == null) return 'Error al procesar la respuesta';

      final jwt = data['jwt'] as String?;
      if (jwt == null || jwt.isEmpty) return 'No se recibió token de autenticación';

      await api.setToken(jwt);

      final userData = data['user'] as Map<String, dynamic>?;
      if (userData == null) return 'No se recibieron datos del usuario';

      _currentUser.value = UserModel.fromJson(userData);

      final meResponse = await api.get('/api/me');
      if (meResponse.success && meResponse.data != null) {
        final meData = meResponse.data as Map<String, dynamic>;
        _currentUser.value = UserModel.fromJson(meData);
      }

      return null;
    } catch (e) {
      return 'Error de conexión: $e';
    } finally {
      _loading.value = false;
    }
  }

  Future<String?> completeSetup({required int careerId, required List<int> specialtyIds}) async {
    final user = _currentUser.value;
    if (user == null) return 'No hay usuario autenticado';

    final api = ApiService.to;
    final response = await api.post(
      '/api/v1/students/${user.id}/setup-career',
      body: {
        'career_id': careerId,
        'specialty_ids': specialtyIds,
      },
    );

    if (!response.success) {
      return response.error ?? response.message ?? 'Error al guardar configuración';
    }

    final meResponse = await api.get('/api/me');
    if (meResponse.success && meResponse.data != null) {
      _currentUser.value = UserModel.fromJson(meResponse.data as Map<String, dynamic>);
    }

    return null;
  }

  Future<bool> tryAutoLogin() async {
    if (_currentUser.value != null) return true;
    final api = ApiService.to;
    if (!api.hasToken) return false;
    _loading.value = true;
    try {
      final response = await api.get('/api/me');
      if (response.success && response.data != null) {
        _currentUser.value = UserModel.fromJson(response.data as Map<String, dynamic>);
        return true;
      }
      await api.clearToken();
      return false;
    } catch (_) {
      await api.clearToken();
      return false;
    } finally {
      _loading.value = false;
    }
  }

  Future<void> logout() async {
    final api = ApiService.to;
    await api.get('/api/sign-out');
    await api.clearToken();
    _currentUser.value = null;
  }
}
