import 'package:dio/dio.dart';
import '../domain/parking_spot.dart';

class LandownerRepository {
  final Dio _dio;

  LandownerRepository(this._dio);

  Future<List<ParkingSpot>> getMySpots() async {
    final response = await _dio.get('spots/');
    final List<dynamic> data = response.data;
    return data.map((e) => ParkingSpot.fromJson(e)).toList();
  }

  Future<ParkingSpot> createSpot(FormData formData) async {
    final response = await _dio.post('spots/', data: formData);
    return ParkingSpot.fromJson(response.data);
  }

  Future<ParkingSpot> updateSpot(int id, FormData formData) async {
    final response = await _dio.patch('spots/$id/', data: formData);
    return ParkingSpot.fromJson(response.data);
  }

  Future<void> deleteSpot(int id) async {
    await _dio.delete('spots/$id/');
  }

  Future<void> toggleSpotAvailability(int id, bool isAvailable) async {
    await _dio.patch('spots/$id/', data: {'is_available': isAvailable});
  }

  Future<List<dynamic>> getMyBookings() async {
    final response = await _dio.get('bookings/');
    return response.data;
  }

  Future<void> updateBookingStatus(int id, String status) async {
    await _dio.patch('bookings/$id/', data: {'status': status});
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final response = await _dio.get('landowner/analytics/');
    return response.data;
  }

  Future<Map<String, dynamic>> verifyQr(String qrData) async {
    final response = await _dio.post('landowner/verify-qr/', data: {'qr_data': qrData});
    return response.data;
  }

  Future<Map<String, dynamic>> sendParkBotMessage(String message) async {
    final response = await _dio.post('landowner/parkbot/', data: {'message': message});
    return response.data;
  }

  Future<List<dynamic>> getMessages() async {
    final response = await _dio.get('messages/');
    return response.data['messages'] ?? [];
  }

  Future<void> sendMessage(int receiverId, String content) async {
    await _dio.post('messages/send/', data: {
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
    // Requires the user ID, usually we can patch /profile/me/ or similar.
    // The ViewSet uses request.user, so patching the first object might work or we can use a dedicated endpoint.
    // In Django UserProfileViewSet returns a list of 1.
    final listResponse = await _dio.get('profile/');
    if (listResponse.data.isNotEmpty) {
      int id = listResponse.data[0]['id'];
      final response = await _dio.patch('profile/$id/', data: data);
      return response.data;
    }
    throw Exception("Profile not found");
  }
}
