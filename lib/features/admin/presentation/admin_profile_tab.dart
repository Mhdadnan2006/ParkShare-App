import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../auth/presentation/auth_providers.dart';
import 'admin_providers.dart';

class AdminProfileTab extends ConsumerStatefulWidget {
  const AdminProfileTab({super.key});

  @override
  ConsumerState<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends ConsumerState<AdminProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initFields(Map<String, dynamic> profile) {
    if (_initialized) return;
    _usernameController.text = profile['username'] ?? '';
    _emailController.text = profile['email'] ?? '';
    _phoneController.text = profile['phone_number'] ?? '';
    _initialized = true;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'username': _usernameController.text.trim(),
      'phone_number': _phoneController.text.trim(),
    };

    final success = await ref.read(adminProfileControllerProvider.notifier).updateProfile(data);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile. Email/Username might be taken.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(adminProfileProvider);
    final state = ref.watch(adminProfileControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondary)),
        error: (err, stack) => Center(
          child: Text('Error loading profile: $err', style: const TextStyle(color: AppTheme.error)),
        ),
        data: (profile) {
          _initFields(profile);
          final username = profile['username'] ?? 'Admin';
          final initials = username.isNotEmpty 
              ? (username.length >= 2 ? username.substring(0, 2) : username[0]).toUpperCase()
              : 'AD';

          return RefreshIndicator(
            onRefresh: () async {
              _initialized = false;
              ref.invalidate(adminProfileProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppTheme.analyticsGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.premiumShadows,
                        border: Border.all(color: AppTheme.borderDark, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              gradient: AppTheme.primaryHeroGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                const Row(
                                  children: [
                                    Icon(Icons.shield, color: AppTheme.premiumHighlight, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'System Administrator • Global',
                                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'ACCOUNT DETAILS',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 16),

                    // Display Name (Username)
                    const Text('Display Name', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      validator: (value) => value == null || value.isEmpty ? 'Display name is required' : null,
                      decoration: InputDecoration(
                        hintText: 'Enter your admin name',
                        fillColor: AppTheme.bgPanel,
                        filled: true,
                        prefixIcon: const Icon(Icons.person_outline, color: AppTheme.textMuted),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.borderDark),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.secondary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Admin Email (Read Only)
                    const Text('Admin Email', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      readOnly: true,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15),
                      decoration: InputDecoration(
                        fillColor: AppTheme.bgPanel.withOpacity(0.4),
                        filled: true,
                        prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textMuted),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppTheme.borderDark.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppTheme.borderDark.withOpacity(0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Emergency Contact (Phone Number)
                    const Text('Emergency Contact', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Enter your phone number',
                        fillColor: AppTheme.bgPanel,
                        filled: true,
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.textMuted),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.borderDark),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.secondary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Actions Row
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: state.isLoading ? null : _saveProfile,
                            child: state.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Danger Zone / Logout button
                    const Divider(color: AppTheme.borderDark),
                    const SizedBox(height: 24),
                    const Text(
                      'DANGER ZONE',
                      style: TextStyle(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () => _confirmLogout(context),
                      icon: const Icon(Icons.logout, color: AppTheme.error),
                      label: const Text('Log Out of Session', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
