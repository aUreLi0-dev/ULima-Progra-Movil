import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? message;
  final String? error;

  ApiResponse({required this.success, this.data, this.message, this.error});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: json['data'],
      message: json['message'] as String?,
      error: json['error'] as String?,
    );
  }
}

class ApiService extends GetxService {
  static ApiService get to => Get.find();

  static const String _baseUrlKey = 'api_base_url';
  static const String _tokenKey = 'jwt_token';
  static const String _defaultBaseUrl = 'http://127.0.0.1:5000';

  String _baseUrl = _defaultBaseUrl;
  String? _token;

  String get baseUrl => _baseUrl;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey) ?? _defaultBaseUrl;
    _token = prefs.getString(_tokenKey);
  }

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<ApiResponse> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: queryParams);
    try {
      final response = await http.get(uri, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, error: 'Error de conexión: $e');
    }
  }

  Future<ApiResponse> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    try {
      final response = await http.post(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, error: 'Error de conexión: $e');
    }
  }

  Future<ApiResponse> put(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    try {
      final response = await http.put(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, error: 'Error de conexión: $e');
    }
  }

  Future<ApiResponse> delete(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    try {
      final response = await http.delete(uri, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(success: false, error: 'Error de conexión: $e');
    }
  }

  ApiResponse _handleResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResponse.fromJson(body);
    } catch (_) {
      return ApiResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        data: response.body,
        message: response.statusCode >= 200 && response.statusCode < 300
            ? 'OK'
            : 'Error',
        error: response.statusCode >= 200 && response.statusCode < 300
            ? null
            : 'HTTP ${response.statusCode}',
      );
    }
  }
}
