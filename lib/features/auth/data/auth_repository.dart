import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network.dart';
import '../domain/user.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<void> sendOtp(String email) async {
    await _dio.post('auth/send-otp/', data: {'email': email});
  }

  Future<void> register(Map<String, dynamic> data, String role) async {
    data['is_driver'] = role == 'driver';
    data['is_landowner'] = role == 'landowner';
    await _dio.post('auth/register/', data: data);
  }

  Future<bool> verifyOtp(String email, String otpCode) async {
    final response = await _dio.post('auth/otp/verify/', data: {
      'email': email,
      'otp_code': otpCode,
    });
    return response.statusCode == 200;
  }

  Future<User?> login(String username, String password) async {
    final response = await _dio.post('auth/login/', data: {
      'username': username,
      'password': password,
    });
    
    final token = response.data['access'];
    final userData = response.data['user'];
    
    // Secure Storage for Token (Phase 7 Security fix)
    await apiClient.secureStorage.write(key: 'auth_token', value: token);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    
    String role = 'driver';
    if (userData['is_landowner'] == true) role = 'landowner';
    if (userData['is_superuser'] == true) role = 'admin';
    
    await prefs.setString('user_role', role);
    
    return User.fromJson(userData);
  }
  
  Future<void> logout() async {
    await apiClient.secureStorage.delete(key: 'auth_token');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
  }
}

