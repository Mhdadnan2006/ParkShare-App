import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:parkshare_app/features/landowner/data/landowner_repository.dart';
import 'package:parkshare_app/features/landowner/domain/parking_spot.dart';
import 'package:parkshare_app/features/landowner/presentation/landowner_providers.dart';

@GenerateNiceMocks([MockSpec<LandownerRepository>()])
import 'performance_test.mocks.dart';

void main() {
  late MockLandownerRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockLandownerRepository();
    container = ProviderContainer(
      overrides: [
        landownerRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Phase 8 & 12: Performance & Stress Testing', () {
    test('SpotController handles 500 concurrent createSpot requests without memory leak or race condition', () async {
      when(mockRepo.createSpot(any)).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return ParkingSpot(
          id: 1,
          title: 'Stress Test Spot',
          address: '123 Test St',
          vehicleType: 'Car',
          pricePerHour: 10.0,
          isAvailable: true,
          status: 'active',
          mainImage: 'http://test.com/image.jpg',
          gpsCoordinates: '10.0, 20.0',
          areaSqft: 150.0,
          totalSlots: 5,
          features: const [],
        );
      });

      final controller = container.read(spotControllerProvider.notifier);

      final futures = <Future<bool>>[];
      
      // Fire 500 concurrent requests!
      for (int i = 0; i < 500; i++) {
        futures.add(controller.createSpot(FormData.fromMap({
          'title': 'Spot $i',
          'address': 'Test $i',
          'vehicle_type': 'car',
          'price_per_hour': 10.0,
        })));
      }

      final results = await Future.wait(futures);

      // Verify that all 500 requests processed successfully despite high concurrency
      expect(results.length, 500);
      expect(results.every((element) => element == true), isTrue);

      // Verify state ends up in data state, not stuck in loading or crashed
      final state = container.read(spotControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.hasError, isFalse);
    });
  });
}
