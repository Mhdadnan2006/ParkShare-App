import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(apiClient.dio);
});

// Spots Moderation Providers
final moderationSpotsProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getModerationSpots();
});

final moderationControllerProvider = AsyncNotifierProvider<ModerationController, void>(() {
  return ModerationController();
});

class ModerationController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> toggleSuspension(String spotId, bool suspend) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.toggleSuspension(spotId, suspend);
      ref.invalidate(moderationSpotsProvider);
      ref.invalidate(adminAnalyticsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

// Analytics Provider
final adminAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getAnalytics();
});

// Users Management Providers
final adminUserRoleFilterProvider = StateProvider<String>((ref) => 'all');
final adminUserStatusFilterProvider = StateProvider<String>((ref) => 'all');
final adminUserQueryProvider = StateProvider<String>((ref) => '');

final adminUsersProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final role = ref.watch(adminUserRoleFilterProvider);
  final status = ref.watch(adminUserStatusFilterProvider);
  final query = ref.watch(adminUserQueryProvider);
  return repo.getUsers(role: role, status: status, query: query);
});

final adminUsersControllerProvider = AsyncNotifierProvider<AdminUsersController, void>(() {
  return AdminUsersController();
});

class AdminUsersController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<Map<String, dynamic>?> suspendUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(adminRepositoryProvider);
      final result = await repo.suspendUser(userId);
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminAnalyticsProvider);
      ref.invalidate(moderationSpotsProvider);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<bool> restoreUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.restoreUser(userId);
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminAnalyticsProvider);
      ref.invalidate(moderationSpotsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<Map<String, dynamic>?> runAutoSuspendOnce() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(adminRepositoryProvider);
      final result = await repo.runAutoSuspendOnce();
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminAnalyticsProvider);
      ref.invalidate(moderationSpotsProvider);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }
}

// Reviews Moderation Providers
final adminReviewRiskFilterProvider = StateProvider<String>((ref) => 'all');
final adminReviewQueryProvider = StateProvider<String>((ref) => '');

final adminReviewsProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final risk = ref.watch(adminReviewRiskFilterProvider);
  final query = ref.watch(adminReviewQueryProvider);
  return repo.getReviews(risk: risk, query: query);
});

final adminReviewsControllerProvider = AsyncNotifierProvider<AdminReviewsController, void>(() {
  return AdminReviewsController();
});

class AdminReviewsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> reviewAction(String reviewId, String action) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.reviewAction(reviewId, action);
      ref.invalidate(adminReviewsProvider);
      ref.invalidate(adminAnalyticsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> rescoreAllReviews() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.rescoreAllReviews();
      ref.invalidate(adminReviewsProvider);
      ref.invalidate(adminAnalyticsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

// Verification Providers
final adminVerificationsProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getPendingVerifications();
});

final adminVerificationsControllerProvider = AsyncNotifierProvider<AdminVerificationsController, void>(() {
  return AdminVerificationsController();
});

class AdminVerificationsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> verificationAction(String userId, String action, {String note = ''}) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.verificationAction(userId, action, note: note);
      ref.invalidate(adminVerificationsProvider);
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminAnalyticsProvider);
      ref.invalidate(moderationSpotsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

// Messaging Providers
final adminSelectedUserChatProvider = StateProvider<String?>((ref) => null);

final adminMessagesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final withUser = ref.watch(adminSelectedUserChatProvider);
  return repo.getAdminMessages(withUser: withUser);
});

final adminMessagesControllerProvider = AsyncNotifierProvider<AdminMessagesController, void>(() {
  return AdminMessagesController();
});

class AdminMessagesController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> sendAdminMessage(int receiverId, String content) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.sendAdminMessage(receiverId, content);
      ref.invalidate(adminMessagesProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

class StateController<T> extends Notifier<T> {
  final T Function(Ref ref) _create;
  StateController(this._create);

  @override
  T build() => _create(ref);

  @override
  set state(T value) => super.state = value;
  @override
  T get state => super.state;
}

NotifierProvider<StateController<T>, T> StateProvider<T>(T Function(Ref ref) create) {
  return NotifierProvider<StateController<T>, T>(() => StateController<T>(create));
}

// Admin Profile Providers
final adminProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getProfile();
});

final adminProfileControllerProvider = AsyncNotifierProvider<AdminProfileController, void>(() {
  return AdminProfileController();
});

class AdminProfileController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.updateProfile(data);
      ref.invalidate(adminProfileProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

