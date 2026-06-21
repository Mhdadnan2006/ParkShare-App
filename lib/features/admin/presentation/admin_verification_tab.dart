import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../core/network.dart';
import 'admin_providers.dart';

class AdminVerificationTab extends ConsumerWidget {
  const AdminVerificationTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationsAsync = ref.watch(adminVerificationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: RefreshIndicator(
        color: AppTheme.secondary,
        backgroundColor: AppTheme.bgPanel,
        onRefresh: () async {
          ref.invalidate(adminVerificationsProvider);
        },
        child: verificationsAsync.when(
          loading: () => _buildSkeletonList(),
          error: (err, stack) => _buildErrorState(ref),
          data: (pendingUsers) {
            if (pendingUsers.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pendingUsers.length,
              itemBuilder: (context, index) {
                final user = pendingUsers[index];
                return _buildVerificationCard(context, ref, user);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildVerificationCard(BuildContext context, WidgetRef ref, Map<String, dynamic> user) {
    final int userId = user['id'];
    final String username = user['username'] ?? 'Unknown User';
    final String email = user['email'] ?? '';
    final String docUrl = user['verification_documents'] ?? '';
    
    String joinedDate = '';
    try {
      final dt = DateTime.parse(user['date_joined']);
      joinedDate = 'Joined ${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {}

    return Card(
      color: AppTheme.bgPanel,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderDark),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.accent.withOpacity(0.1),
                  child: const Icon(Icons.business, color: AppTheme.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.borderDark),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.description_outlined, color: AppTheme.textMuted, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Land Deed / Property Tax Document',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (docUrl.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _openDocument(docUrl),
                    icon: const Icon(Icons.open_in_new, size: 14, color: AppTheme.accent),
                    label: const Text('View', style: TextStyle(color: AppTheme.accent, fontSize: 13)),
                  )
                else
                  const Text('No Document Uploaded', style: TextStyle(color: AppTheme.error, fontSize: 12)),
              ],
            ),
            if (joinedDate.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                joinedDate,
                style: TextStyle(color: AppTheme.textMuted.withOpacity(0.6), fontSize: 11),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _rejectVerification(context, ref, userId.toString(), username),
                    child: const Text('Reject', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _approveVerification(context, ref, userId.toString(), username),
                    child: const Text('Approve & Verify', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _openDocument(String url) async {
    final Uri uri;
    if (url.startsWith('http')) {
      uri = Uri.parse(url);
    } else {
      // Relative path from backend server
      uri = Uri.parse('${ApiClient.baseServerUrl}$url');
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _approveVerification(BuildContext context, WidgetRef ref, String userId, String username) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgPanel,
        title: const Text('Approve Verification?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Do you want to approve $username? This will verify their landowner credentials and automatically activate all their pending parking listings.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading spinner
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.secondary)),
    );

    final success = await ref
        .read(adminVerificationsControllerProvider.notifier)
        .verificationAction(userId, 'approve');

    if (!context.mounted) return;
    Navigator.pop(context); // Pop spinner

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Landowner $username verified successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to verify landowner.')),
      );
    }
  }

  void _rejectVerification(BuildContext context, WidgetRef ref, String userId, String username) async {
    final TextEditingController noteController = TextEditingController();

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgPanel,
        title: const Text('Reject Verification?', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specify rejection reason for landowner $username. Their listings will be moved to rejected status.',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Enter reason note here...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppTheme.bgDark,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.error),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading spinner
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.secondary)),
    );

    final success = await ref
        .read(adminVerificationsControllerProvider.notifier)
        .verificationAction(userId, 'reject', note: noteController.text.trim());

    if (!context.mounted) return;
    Navigator.pop(context); // Pop spinner

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification for $username rejected.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to complete rejection.')),
      );
    }
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        height: 180,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.bgPanel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderDark),
        ),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 40),
          const SizedBox(height: 12),
          const Text('Failed to load pending verifications.', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(adminVerificationsProvider),
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
          const Icon(Icons.verified_user_outlined, color: AppTheme.secondary, size: 48),
          const SizedBox(height: 16),
          const Text(
            'All landowners verified!',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'No landowner accounts are currently awaiting document review.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
