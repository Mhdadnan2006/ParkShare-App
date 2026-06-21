import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'network.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/registration_screen.dart';
import '../features/auth/presentation/otp_verification_screen.dart';

import '../features/driver/presentation/driver_dashboard.dart';
import '../features/landowner/presentation/landowner_dashboard.dart';
import '../features/admin/presentation/admin_dashboard.dart';

final goRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    String? token = await apiClient.secureStorage.read(key: 'auth_token');
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      token = prefs.getString('auth_token');
    }
    final role = prefs.getString('user_role'); // 'driver', 'landowner', 'admin'

    final loggingIn = state.uri.toString() == '/login';
    final registering = state.uri.toString() == '/register';

    if (token == null || token.isEmpty) {
      return (loggingIn || registering) ? null : '/login';
    }

    if (loggingIn || registering) {
      if (role == 'driver') return '/driver';
      if (role == 'landowner') return '/landowner';
      if (role == 'admin') return '/admin';
    }

    // Strict Role-Based Access Control (Phase 10 Security Fix)
    final path = state.uri.toString();
    if (path.startsWith('/admin') && role != 'admin') return '/$role';
    if (path.startsWith('/landowner') && role != 'landowner' && role != 'admin') return '/$role';
    if (path.startsWith('/driver') && role != 'driver' && role != 'admin') return '/$role';

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegistrationScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) => const OtpVerificationScreen(),
    ),
    GoRoute(
      path: '/driver',
      builder: (context, state) => const DriverDashboard(),
    ),
    GoRoute(
      path: '/landowner',
      builder: (context, state) => const LandownerDashboard(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboard(),
    ),
  ],
);
