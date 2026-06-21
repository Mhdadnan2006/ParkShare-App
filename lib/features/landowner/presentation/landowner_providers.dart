import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network.dart';
import '../data/landowner_repository.dart';
import '../domain/parking_spot.dart';

final landownerRepositoryProvider = Provider<LandownerRepository>((ref) {
  return LandownerRepository(apiClient.dio);
});

final mySpotsProvider = FutureProvider<List<ParkingSpot>>((ref) async {
  final repo = ref.watch(landownerRepositoryProvider);
  return repo.getMySpots();
});

final spotControllerProvider = AsyncNotifierProvider<SpotController, void>(() {
  return SpotController();
});

class SpotController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> createSpot(FormData formData) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(landownerRepositoryProvider);
      await repo.createSpot(formData);
      ref.invalidate(mySpotsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> updateSpot(int id, FormData formData) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(landownerRepositoryProvider);
      await repo.updateSpot(id, formData);
      ref.invalidate(mySpotsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> deleteSpot(int id) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(landownerRepositoryProvider);
      await repo.deleteSpot(id);
      ref.invalidate(mySpotsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> toggleSpotAvailability(int id, bool isAvailable) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(landownerRepositoryProvider);
      await repo.toggleSpotAvailability(id, isAvailable);
      ref.invalidate(mySpotsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final analyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(landownerRepositoryProvider);
  return repo.getAnalytics();
});

final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(landownerRepositoryProvider);
  return repo.getProfile();
});

final messagesProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(landownerRepositoryProvider);
  return repo.getMessages();
});

final profileControllerProvider = AsyncNotifierProvider<ProfileController, void>(() {
  return ProfileController();
});

class ProfileController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(landownerRepositoryProvider);
      await repo.updateProfile(data);
      ref.invalidate(profileProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final landownerBookingsProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(landownerRepositoryProvider);
  return repo.getMyBookings();
});

final qrScannerControllerProvider = AsyncNotifierProvider<QrScannerController, void>(() {
  return QrScannerController();
});

class QrScannerController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<Map<String, dynamic>?> verifyQr(String qrData) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(landownerRepositoryProvider);
      final result = await repo.verifyQr(qrData);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }
}
