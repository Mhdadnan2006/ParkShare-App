import 'package:flutter_test/flutter_test.dart';
import 'package:parkshare_app/features/driver/domain/booking.dart';

void main() {
  group('Booking Model Tests', () {
    test('fromJson should parse correctly', () {
      final Map<String, dynamic> json = {
        'id': 202,
        'spot': {
          'id': 101,
          'title': 'Test Spot',
          'address': '123 Test Street',
          'price_per_hour': 15.5
        },
        'vehicle_no': 'KA-01-HH-1234',
        'vehicle_type': 'Car',
        'start_time': '2026-06-08T10:00:00Z',
        'end_time': '2026-06-08T12:00:00Z',
        'total_cost': 31.0,
        'status': 'confirmed',
        'qr_code': 'http://example.com/qr.png',
        'license_image': 'http://example.com/license.jpg'
      };

      final booking = Booking.fromJson(json);

      expect(booking.id, 202);
      expect(booking.spot.id, 101);
      expect(booking.spot.title, 'Test Spot');
      expect(booking.vehicleNo, 'KA-01-HH-1234');
      expect(booking.vehicleType, 'Car');
      expect(booking.startTime.toUtc().toIso8601String(), '2026-06-08T10:00:00.000Z');
      expect(booking.endTime.toUtc().toIso8601String(), '2026-06-08T12:00:00.000Z');
      expect(booking.totalCost, 31.0);
      expect(booking.status, 'confirmed');
      expect(booking.qrCodeUrl, 'http://example.com/qr.png');
      expect(booking.licenseImageUrl, 'http://example.com/license.jpg');
    });

    test('fromJson should handle null/missing values gracefully', () {
      final Map<String, dynamic> json = {};

      final booking = Booking.fromJson(json);

      expect(booking.id, 0);
      expect(booking.spot.id, 0);
      expect(booking.vehicleNo, '');
      expect(booking.vehicleType, 'Car');
      expect(booking.totalCost, 0.0);
      expect(booking.status, 'pending');
      expect(booking.qrCodeUrl, null);
      expect(booking.licenseImageUrl, null);
      expect(booking.startTime.isBefore(booking.endTime), true); // Default end time should be after start time
    });
  });
}
