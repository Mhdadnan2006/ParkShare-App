import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network.dart';
import '../../landowner/domain/parking_spot.dart';
import '../data/driver_repository.dart';
import '../domain/booking.dart';

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepository(apiClient.dio);
});

final searchLocationProvider = NotifierProvider<SearchLocationNotifier, Map<String, double>>(() {
  return SearchLocationNotifier();
});

class SearchLocationNotifier extends Notifier<Map<String, double>> {
  @override
  Map<String, double> build() => {'lat': 0.0, 'lng': 0.0};

  void updateLocation(double lat, double lng) {
    state = {'lat': lat, 'lng': lng};
  }
}

final searchedSpotsProvider = FutureProvider<List<ParkingSpot>>((ref) async {
  final repo = ref.watch(driverRepositoryProvider);
  final location = ref.watch(searchLocationProvider);
  if (location['lat'] == 0.0 && location['lng'] == 0.0) return [];
  return repo.searchSpots(location['lat']!, location['lng']!);
});

final myBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final repo = ref.watch(driverRepositoryProvider);
  return repo.getMyBookings();
});

final bookingControllerProvider = AsyncNotifierProvider<BookingController, Booking?>(() {
  return BookingController();
});

class BookingController extends AsyncNotifier<Booking?> {
  @override
  FutureOr<Booking?> build() => null;

  Future<bool> createBooking(FormData formData) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(driverRepositoryProvider);
      final booking = await repo.createBooking(formData);
      ref.invalidate(myBookingsProvider);
      state = AsyncValue.data(booking);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> submitReview(int spotId, int bookingId, int rating, String comment) async {
    try {
      final repo = ref.read(driverRepositoryProvider);
      await repo.submitReview(spotId, bookingId, rating, comment);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final driverProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(driverRepositoryProvider);
  return repo.getProfile();
});

final driverProfileControllerProvider = AsyncNotifierProvider<DriverProfileController, void>(() {
  return DriverProfileController();
});

class DriverProfileController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(driverRepositoryProvider);
      await repo.updateProfile(data);
      ref.invalidate(driverProfileProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final driverMessagesProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(driverRepositoryProvider);
  return repo.getMessages();
});

final driverMessageControllerProvider = AsyncNotifierProvider<DriverMessageController, void>(() {
  return DriverMessageController();
});

class DriverMessageController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> sendMessage(int receiverId, String content) async {
    try {
      final repo = ref.read(driverRepositoryProvider);
      await repo.sendMessage(receiverId, content);
      ref.invalidate(driverMessagesProvider);
      return true;
    } catch (e) {
      return false;
    }
  }
}

