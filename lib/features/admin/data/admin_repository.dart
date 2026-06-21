import 'package:dio/dio.dart';

class AdminRepository {
  final Dio _dio;

  AdminRepository(this._dio);

  Future<List<dynamic>> getModerationSpots() async {
    final response = await _dio.get('admin/spots/moderation/');
    return response.data as List<dynamic>;
  }

  Future<void> toggleSuspension(String spotId, bool suspend) async {
    await _dio.post('admin/spots/$spotId/suspend/', data: {'suspend': suspend});
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final response = await _dio.get('admin/analytics/');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getUsers({String role = 'all', String status = 'all', String query = ''}) async {
    final response = await _dio.get('admin/users/', queryParameters: {
      'role': role,
      'status': status,
      'q': query,
    });
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> suspendUser(String userId) async {
    final response = await _dio.post('admin/users/$userId/suspend/');
    return response.data as Map<String, dynamic>;
  }

  Future<void> restoreUser(String userId) async {
    await _dio.post('admin/users/$userId/restore/');
  }

  Future<Map<String, dynamic>> runAutoSuspendOnce() async {
    final response = await _dio.post('admin/users/auto-suspend/');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getReviews({String risk = 'all', String query = ''}) async {
    final response = await _dio.get('admin/reviews/', queryParameters: {
      'risk': risk,
      'q': query,
    });
    return response.data as List<dynamic>;
  }

  Future<void> reviewAction(String reviewId, String action) async {
    await _dio.post('admin/reviews/$reviewId/action/', data: {'action': action});
  }

  Future<void> rescoreAllReviews() async {
    await _dio.post('admin/reviews/rescore-all/');
  }

  Future<List<dynamic>> getPendingVerifications() async {
    final response = await _dio.get('admin/verification/');
    return response.data as List<dynamic>;
  }

  Future<void> verificationAction(String userId, String action, {String note = ''}) async {
    await _dio.post('admin/verification/$userId/action/', data: {
      'action': action,
      'note': note,
    });
  }

  Future<Map<String, dynamic>> getAdminMessages({String? withUser}) async {
    final response = await _dio.get(
      'admin/messages/',
      queryParameters: {
        if (withUser != null && withUser.isNotEmpty) 'with_user': withUser,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> sendAdminMessage(int receiverId, String content) async {
    await _dio.post('admin/messages/send/', data: {
      'receiver_id': receiverId,
      'content': content,
    });
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('profile/');
    if (response.data.isNotEmpty) {
      return response.data[0];
    }
    throw Exception("Profile not found");
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final listResponse = await _dio.get('profile/');
    if (listResponse.data.isNotEmpty) {
      int id = listResponse.data[0]['id'];
      final response = await _dio.patch('profile/$id/', data: data);
      return response.data;
    }
    throw Exception("Profile not found");
  }
}
