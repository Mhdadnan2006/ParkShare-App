import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import 'admin_providers.dart';

class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final selectedRole = ref.watch(adminUserRoleFilterProvider);
    final selectedStatus = ref.watch(adminUserStatusFilterProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Column(
        children: [
          // Filter Panel
          _buildFilterHeader(context, selectedRole, selectedStatus),

          // Users list
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.secondary,
              backgroundColor: AppTheme.bgPanel,
              onRefresh: () async {
                ref.invalidate(adminUsersProvider);
              },
              child: usersAsync.when(
                loading: () => _buildSkeletonList(),
                error: (err, stack) => _buildErrorState(),
                data: (users) {
                  if (users.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _buildUserCard(context, user);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(BuildContext context, String currentRole, String currentStatus) {
    return Container(
      color: AppTheme.bgPanel,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          // Search & Scanner trigger
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (val) {
                    ref.read(adminUserQueryProvider.notifier).state = val;
                  },
                  decoration: InputDecoration(
                    hintText: 'Search username, email, phone...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.bgDark,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderDark),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.secondary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Run Auto-suspend trigger
              Tooltip(
                message: 'Run Suspicion Detectors System-wide',
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.shield_outlined, color: AppTheme.accent),
                    onPressed: () => _triggerAutoSuspendScan(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Horizontal Role selections
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRoleFilterChip('All Accounts', 'all', currentRole),
                _buildRoleFilterChip('Drivers', 'driver', currentRole),
                _buildRoleFilterChip('Landowners', 'landowner', currentRole),
                _buildRoleFilterChip('Admins', 'admin', currentRole),
                _buildRoleFilterChip('Unassigned', 'user', currentRole),
                const SizedBox(width: 8),
                const Text('|', style: TextStyle(color: AppTheme.borderDark)),
                const SizedBox(width: 8),
                _buildStatusFilterChip('All Statuses', 'all', currentStatus),
                _buildStatusFilterChip('Active', 'active', currentStatus),
                _buildStatusFilterChip('Suspended', 'suspended', currentStatus),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilterChip(String label, String value, String current) {
    final bool isSelected = current == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textMuted,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          if (selected) {
            ref.read(adminUserRoleFilterProvider.notifier).state = value;
          }
        },
        selectedColor: AppTheme.secondary,
        backgroundColor: AppTheme.bgDark,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.transparent : AppTheme.borderDark,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, String value, String current) {
    final bool isSelected = current == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textMuted,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          if (selected) {
            ref.read(adminUserStatusFilterProvider.notifier).state = value;
          }
        },
        selectedColor: value == 'suspended' ? AppTheme.error : AppTheme.secondary,
        backgroundColor: AppTheme.bgDark,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.transparent : AppTheme.borderDark,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    final bool isActive = user['is_active'] ?? true;
    final bool isDriver = user['is_driver'] ?? false;
    final bool isLandowner = user['is_landowner'] ?? false;
    final bool isVerified = user['is_verified'] ?? false;

    // Resolve Role badging
    List<Widget> badges = [];
    if (user['id'] == 1 || user['username'] == 'admin') {
      badges.add(_buildBadge('SYSTEM SUPERUSER', AppTheme.premiumHighlight));
    } else {
      if (isLandowner) badges.add(_buildBadge('LANDOWNER', AppTheme.accent));
      if (isDriver) badges.add(_buildBadge('DRIVER', AppTheme.secondary));
      if (isVerified) badges.add(_buildBadge('VERIFIED', AppTheme.success));
      if (!isLandowner && !isDriver) badges.add(_buildBadge('USER', AppTheme.textMuted));
    }

    String dateStr = '';
    try {
      final dt = DateTime.parse(user['date_joined']);
      dateStr = 'Joined ${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {}

    return Card(
      color: AppTheme.bgPanel,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive ? AppTheme.borderDark : AppTheme.error.withValues(alpha: 0.4),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        title: Row(
          children: [
            Text(
              user['username'] ?? 'Unknown User',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            if (!isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.error, width: 0.5),
                ),
                child: const Text(
                  'SUSPENDED',
                  style: TextStyle(color: AppTheme.error, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(user['email'] ?? 'No email', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            if (user['phone_number'] != null && user['phone_number'].toString().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(user['phone_number'], style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: badges,
            ),
            if (dateStr.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(dateStr, style: TextStyle(color: AppTheme.textMuted.withOpacity(0.7), fontSize: 11)),
            ],
            if (!isActive && user['suspension_reason'] != null && user['suspension_reason'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Text(
                  'Reason: ${user['suspension_reason']}',
                  style: const TextStyle(color: AppTheme.error, fontSize: 11),
                ),
              ),
            ]
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppTheme.textMuted.withOpacity(0.5),
          size: 14,
        ),
        onTap: () => _showUserActions(context, user),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
    );
  }

  void _showUserActions(BuildContext context, Map<String, dynamic> user) {
    final bool isActive = user['is_active'] ?? true;
    final int userId = user['id'];
    final String username = user['username'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  username,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  user['email'] ?? '',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (isActive) ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _suspendUserAction(context, userId.toString(), username);
                    },
                    child: const Text('Suspend Account', style: TextStyle(color: Colors.white)),
                  ),
                ] else ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _restoreUserAction(context, userId.toString(), username);
                    },
                    child: const Text('Restore Account', style: TextStyle(color: Colors.white)),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _suspendUserAction(BuildContext context, String userId, String username) async {
    // Show spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.secondary)),
    );

    final result = await ref.read(adminUsersControllerProvider.notifier).suspendUser(userId);
    if (!context.mounted) return;
    Navigator.pop(context); // Remove spinner

    if (result != null && result['status'] == 'success') {
      // Show detector results
      final confidence = result['confidence'] ?? 0;
      final reasonDisplay = result['reason_display'] ?? 'Manual Suspension';
      final List<dynamic> suspendedSpots = result['suspended_spots'] ?? [];

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.bgPanel,
          title: const Row(
            children: [
              Icon(Icons.shield, color: AppTheme.error),
              SizedBox(width: 8),
              Text('Suspension Report', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('User $username has been suspended.', style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                const Text('Heuristic Detector Results:', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('Confidence Level: ', style: TextStyle(color: Colors.white, fontSize: 13)),
                    Text('$confidence%', style: TextStyle(color: confidence > 75 ? AppTheme.error : AppTheme.warning, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Trigger Category: $reasonDisplay', style: const TextStyle(color: Colors.white, fontSize: 13)),
                const SizedBox(height: 16),
                Text('Disabled Listings (${suspendedSpots.length}):', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                if (suspendedSpots.isEmpty)
                  const Text('No parking spots disabled.', style: TextStyle(color: Colors.white, fontSize: 13))
                else
                  ...suspendedSpots.map((spotId) => Text('- Spot ID: $spotId', style: const TextStyle(color: AppTheme.error, fontSize: 13))),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: AppTheme.secondary)),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to suspend user. Check backend logic.')),
      );
    }
  }

  void _restoreUserAction(BuildContext context, String userId, String username) async {
    // Show spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.secondary)),
    );

    final success = await ref.read(adminUsersControllerProvider.notifier).restoreUser(userId);
    if (!context.mounted) return;
    Navigator.pop(context); // Remove spinner

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User $username restored successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to restore user.')),
      );
    }
  }

  void _triggerAutoSuspendScan(BuildContext context) async {
    // Confirmation
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgPanel,
        title: const Text('Run Suspend Detectors?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will trigger checking processes on all active listings and users to automatically suspend violating records based on safety rules and confidence weights. Do you want to run it now?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Run Scan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show progress dialog
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: AppTheme.bgPanel,
        content: Row(
          children: [
            CircularProgressIndicator(color: AppTheme.secondary),
            SizedBox(width: 20),
            Text('Processing security scan...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    final result = await ref.read(adminUsersControllerProvider.notifier).runAutoSuspendOnce();
    if (!context.mounted) return;
    Navigator.pop(context); // Remove progress dialog

    if (result != null && result['status'] == 'success') {
      final spots = result['suspended_spots'] ?? 0;
      final users = result['suspended_users'] ?? 0;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.bgPanel,
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppTheme.success),
              SizedBox(width: 8),
              Text('Security Scan Done', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            'The background suspension check has completed successfully.\n\n'
            '- Suspended Spots: $spots\n'
            '- Suspended Accounts: $users',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: AppTheme.secondary)),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to complete automated check.')),
      );
    }
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        height: 110,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgPanel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderDark),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 40),
          const SizedBox(height: 12),
          const Text('Failed to load users registries.', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(adminUsersProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, color: AppTheme.textMuted.withOpacity(0.5), size: 48),
          const SizedBox(height: 12),
          const Text('No accounts match the selected filters.', style: TextStyle(color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
