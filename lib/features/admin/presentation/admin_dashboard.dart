import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../auth/presentation/auth_providers.dart';
import 'admin_analytics_tab.dart';
import 'admin_users_tab.dart';
import 'admin_verification_tab.dart';
import 'admin_reviews_tab.dart';
import 'admin_messages_tab.dart';
import 'admin_profile_tab.dart';
import 'spot_moderation_list.dart';
import 'admin_providers.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const AdminAnalyticsTab(),
    const SpotModerationList(),
    const AdminUsersTab(),
    const AdminVerificationTab(),
    const AdminReviewsTab(),
    const AdminMessagesTab(),
    const AdminProfileTab(),
  ];

  final List<String> _titles = [
    'System Analytics',
    'Spot Moderation',
    'User Management',
    'Verification Center',
    'Review Moderation',
    'Support Console',
    'My Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titles[_currentIndex],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Text(
              'ParkShare Enterprise Control',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: AppTheme.bgPanel,
        elevation: 0,
        actions: [
          // Clear active filter state when switching views
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textMuted, size: 20),
            onPressed: () {
              ref.invalidate(adminAnalyticsProvider);
              ref.invalidate(moderationSpotsProvider);
              ref.invalidate(adminUsersProvider);
              ref.invalidate(adminVerificationsProvider);
              ref.invalidate(adminReviewsProvider);
              ref.invalidate(adminMessagesProvider);
              ref.invalidate(adminProfileProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.error, size: 20),
            onPressed: () => _confirmLogout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: _tabs[_currentIndex]),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: AppTheme.bgPanel,
          selectedItemColor: AppTheme.secondary,
          unselectedItemColor: AppTheme.textMuted,
          selectedFontSize: 9,
          unselectedFontSize: 9,
          iconSize: 20,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics, color: AppTheme.secondary),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map, color: AppTheme.secondary),
              label: 'Spots',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people, color: AppTheme.secondary),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.domain_verification_outlined),
              activeIcon: Icon(Icons.domain_verification, color: AppTheme.secondary),
              label: 'Verifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.rate_review_outlined),
              activeIcon: Icon(Icons.rate_review, color: AppTheme.secondary),
              label: 'Reviews',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum, color: AppTheme.secondary),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: AppTheme.secondary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) async {
    final bool? logoutConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgPanel,
        title: const Text('Confirm Logout?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out of the admin panel?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (logoutConfirm == true) {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }
}
