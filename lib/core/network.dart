import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseServerUrl = 'http://10.112.34.229:8000';
  static const String baseUrl = '$baseServerUrl/api/v1/';
  final _secureStorage = const FlutterSecureStorage();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  ApiClient() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Securely fetch token from KeyStore/Keychain instead of SharedPreferences XML
        String? token = await _secureStorage.read(key: 'auth_token');
        if (token == null || token.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          token = prefs.getString('auth_token');
        }
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle global 401 Unauthorized errors (Expired Token)
        if (error.response?.statusCode == 401) {
           await _secureStorage.delete(key: 'auth_token');
           final prefs = await SharedPreferences.getInstance();
           await prefs.remove('auth_token');
        }
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;
  FlutterSecureStorage get secureStorage => _secureStorage;
}

final apiClient = ApiClient();
