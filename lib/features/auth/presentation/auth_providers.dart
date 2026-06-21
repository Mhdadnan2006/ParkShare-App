import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(apiClient.dio);
});

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<User?> {
  @override
  FutureOr<User?> build() => null;

  Future<bool> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.login(username, password);
      state = AsyncValue.data(user);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data, String role) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.register(data, role);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> sendOtp(String email) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.sendOtp(email);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otpCode) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final success = await repo.verifyOtp(email, otpCode);
      state = const AsyncValue.data(null);
      return success;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncValue.data(null);
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

final registrationEmailProvider = StateProvider<String>((ref) => '');


