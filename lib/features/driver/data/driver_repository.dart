import 'package:dio/dio.dart';
import '../../landowner/domain/parking_spot.dart';
import '../domain/booking.dart';

class DriverRepository {
  final Dio _dio;

  DriverRepository(this._dio);

  Future<List<ParkingSpot>> searchSpots(double lat, double lng, {double radius = 5.0}) async {
    final response = await _dio.get('spots/', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
    });
    final List<dynamic> data = response.data;
    return data.map((e) => ParkingSpot.fromJson(e)).toList();
  }

  Future<Booking> createBooking(FormData formData) async {
    final response = await _dio.post('bookings/', data: formData);
    return Booking.fromJson(response.data);
  }

  Future<List<Booking>> getMyBookings() async {
    final response = await _dio.get('bookings/');
    final List<dynamic> data = response.data;
    return data.map((e) => Booking.fromJson(e)).toList();
  }

  Future<Booking> getBookingDetails(int id) async {
    final response = await _dio.get('bookings/$id/');
    return Booking.fromJson(response.data);
  }

  Future<void> submitReview(int spotId, int bookingId, int rating, String comment) async {
    await _dio.post('reviews/', data: {
      'spot': spotId,
      'booking': bookingId,
      'rating': rating,
      'comment': comment,
    });
  }

  Future<void> captureGps(double lat, double lng) async {
    await _dio.post('driver/gps/capture/', data: {
      'lat': lat,
      'lon': lng,
      'source': 'mobile_app',
    });
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
    final listResponse = await _dio.get('profile/');
    if (listResponse.data.isNotEmpty) {
      int id = listResponse.data[0]['id'];
      final response = await _dio.patch('profile/$id/', data: data);
      return response.data;
    }
    throw Exception("Profile not found");
  }

  Future<Map<String, dynamic>> getRoute(double startLat, double startLng, double endLat, double endLng) async {
    final response = await _dio.get('driver/navigation/route/', queryParameters: {
      'start_lat': startLat,
      'start_lon': startLng,
      'end_lat': endLat,
      'end_lon': endLng,
    });
    return response.data;
  }
}

