import 'package:flutter_test/flutter_test.dart';
import 'package:parkshare_app/features/landowner/domain/parking_spot.dart';

void main() {
  group('ParkingSpot Model Tests', () {
    test('fromJson should parse correctly', () {
      final Map<String, dynamic> json = {
        'id': 101,
        'title': 'Test Spot',
        'address': '123 Test Street',
        'vehicle_type': 'car',
        'price_per_hour': 15.5,
        'is_available': true,
        'status': 'active',
        'main_image': 'http://example.com/image.jpg'
      };

      final spot = ParkingSpot.fromJson(json);

      expect(spot.id, 101);
      expect(spot.title, 'Test Spot');
      expect(spot.address, '123 Test Street');
      expect(spot.vehicleType, 'car');
      expect(spot.pricePerHour, 15.5);
      expect(spot.isAvailable, true);
      expect(spot.status, 'active');
      expect(spot.mainImage, 'http://example.com/image.jpg');
    });

    test('fromJson should handle null/missing values gracefully', () {
      final Map<String, dynamic> json = {};

      final spot = ParkingSpot.fromJson(json);

      expect(spot.id, 0);
      expect(spot.title, '');
      expect(spot.address, '');
      expect(spot.vehicleType, 'car');
      expect(spot.pricePerHour, 0.0);
      expect(spot.isAvailable, true);
      expect(spot.status, 'pending');
      expect(spot.mainImage, null);
    });
  });
}
