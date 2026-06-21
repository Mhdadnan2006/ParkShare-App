import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import 'admin_providers.dart';

class AdminAnalyticsTab extends ConsumerWidget {
  const AdminAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(adminAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: RefreshIndicator(
        color: AppTheme.secondary,
        backgroundColor: AppTheme.bgPanel,
        onRefresh: () async {
          ref.invalidate(adminAnalyticsProvider);
        },
        child: analyticsAsync.when(
          loading: () => _buildLoadingSkeleton(),
          error: (err, stack) => _buildErrorState(ref),
          data: (data) => _buildContent(context, data),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildSkeletonTitle(),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => _buildSkeletonCard(),
          ),
          const SizedBox(height: 24),
          _buildSkeletonLargeCard(),
          const SizedBox(height: 20),
          _buildSkeletonLargeCard(),
        ],
      ),
    );
  }

  Widget _buildSkeletonTitle() {
    return Container(
      width: 180,
      height: 24,
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 80,
                height: 12,
                color: AppTheme.bgDark,
              ),
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppTheme.bgDark,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 100,
            height: 24,
            color: AppTheme.bgDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLargeCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 150,
            height: 16,
            color: AppTheme.bgDark,
          ),
          const SizedBox(height: 24),
          Container(
            height: 12,
            width: double.infinity,
            color: AppTheme.bgDark,
          ),
          const Spacer(),
          Container(
            height: 12,
            width: double.infinity,
            color: AppTheme.bgDark,
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: double.infinity,
            color: AppTheme.bgDark,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 500,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Analytics',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your backend connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(adminAnalyticsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    final revenue = data['revenue'] ?? 0.0;
    final users = data['users'] ?? 0;
    final pending = data['pending'] ?? 0;
    final disputes = data['disputes'] ?? 0;
    final bookings = data['bookings'] ?? 0;
    final newUsers = data['new_users'] ?? 0;
    final avgRating = data['avg_rating'] ?? 0.0;

    final roleBreakdown = data['role_breakdown'] as Map<String, dynamic>? ?? {};
    final spotStatusCounts = data['spot_status_counts'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Live enterprise monitoring and statistics',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          // KPI grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.35,
            children: [
              _KpiCard(
                title: 'Revenue Generated',
                value: '\$${revenue.toStringAsFixed(2)}',
                icon: Icons.monetization_on_outlined,
                iconColor: AppTheme.secondary,
                gradient: const LinearGradient(
                  colors: [AppTheme.bgPanel, Color(0xFF132D2F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              _KpiCard(
                title: 'Active Accounts',
                value: users.toString(),
                icon: Icons.people_outline,
                iconColor: AppTheme.accent,
              ),
              _KpiCard(
                title: 'Pending Approvals',
                value: pending.toString(),
                icon: Icons.domain_verification,
                iconColor: AppTheme.premiumHighlight,
                isHighlight: pending > 0,
              ),
              _KpiCard(
                title: 'Flagged Reviews',
                value: disputes.toString(),
                icon: Icons.gavel_outlined,
                iconColor: AppTheme.error,
                isHighlight: disputes > 0,
              ),
              _KpiCard(
                title: 'Total Bookings',
                value: bookings.toString(),
                icon: Icons.calendar_today_outlined,
                iconColor: AppTheme.secondary,
              ),
              _KpiCard(
                title: 'New Signups',
                value: '+$newUsers',
                icon: Icons.trending_up,
                iconColor: AppTheme.accent,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Avg Rating
          _buildRatingCard(avgRating),
          const SizedBox(height: 20),

          // Role distribution card
          _RoleBreakdownCard(breakdown: roleBreakdown),
          const SizedBox(height: 20),

          // Spot status card
          _SpotStatusCard(counts: spotStatusCounts),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRatingCard(double rating) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Average Review Rating',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'System-wide rating across all evaluated spots.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppTheme.premiumHighlight,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  final double val = index + 1;
                  return Icon(
                    val <= rating
                        ? Icons.star
                        : (val - rating <= 0.5 ? Icons.star_half : Icons.star_border),
                    color: AppTheme.premiumHighlight,
                    size: 16,
                  );
                }),
              )
            ],
          )
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final LinearGradient? gradient;
  final bool isHighlight;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.gradient,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight ? iconColor.withOpacity(0.5) : AppTheme.borderDark,
          width: isHighlight ? 1.5 : 1,
        ),
        gradient: gradient,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(icon, color: iconColor, size: 18),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBreakdownCard extends StatelessWidget {
  final Map<String, dynamic> breakdown;

  const _RoleBreakdownCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final int admins = breakdown['admins'] ?? 0;
    final int landowners = breakdown['landowners'] ?? 0;
    final int drivers = breakdown['drivers'] ?? 0;
    final int others = breakdown['others'] ?? 0;
    final int total = admins + landowners + drivers + others;

    double adminPct = total > 0 ? admins / total : 0.0;
    double landownerPct = total > 0 ? landowners / total : 0.0;
    double driverPct = total > 0 ? drivers / total : 0.0;
    double otherPct = total > 0 ? others / total : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Accounts Registry',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Stacked horizontal bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (driverPct > 0)
                    Expanded(
                      flex: (driverPct * 100).round(),
                      child: Container(color: AppTheme.secondary),
                    ),
                  if (landownerPct > 0)
                    Expanded(
                      flex: (landownerPct * 100).round(),
                      child: Container(color: AppTheme.accent),
                    ),
                  if (adminPct > 0)
                    Expanded(
                      flex: (adminPct * 100).round(),
                      child: Container(color: AppTheme.premiumHighlight),
                    ),
                  if (otherPct > 0)
                    Expanded(
                      flex: (otherPct * 100).round(),
                      child: Container(color: AppTheme.textMuted),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend list
          _buildRoleRow('Drivers', drivers, driverPct, AppTheme.secondary),
          const SizedBox(height: 8),
          _buildRoleRow('Landowners', landowners, landownerPct, AppTheme.accent),
          const SizedBox(height: 8),
          _buildRoleRow('Administrators', admins, adminPct, AppTheme.premiumHighlight),
          const SizedBox(height: 8),
          _buildRoleRow('Others', others, otherPct, AppTheme.textMuted),
        ],
      ),
    );
  }

  Widget _buildRoleRow(String roleName, int count, double pct, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(roleName, style: const TextStyle(color: Colors.white, fontSize: 14)),
        const Spacer(),
        Text(
          '$count (${(pct * 100).toStringAsFixed(1)}%)',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
      ],
    );
  }
}

class _SpotStatusCard extends StatelessWidget {
  final Map<String, dynamic> counts;

  const _SpotStatusCard({required this.counts});

  @override
  Widget build(BuildContext context) {
    final active = counts['active'] ?? 0;
    final pending = counts['pending'] ?? 0;
    final rejected = counts['rejected'] ?? 0;
    final suspended = counts['suspended'] ?? 0;
    final total = active + pending + rejected + suspended;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parking Spot Listings Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildStatusRow('Active / Operational', active, total, AppTheme.success),
          const SizedBox(height: 12),
          _buildStatusRow('Pending Approval', pending, total, AppTheme.warning),
          const SizedBox(height: 12),
          _buildStatusRow('Suspended Listings', suspended, total, AppTheme.error),
          const SizedBox(height: 12),
          _buildStatusRow('Rejected Spots', rejected, total, AppTheme.textMuted),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, int val, int total, Color color) {
    double pct = total > 0 ? val / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
            Text(
              '$val (${(pct * 100).toStringAsFixed(1)}%)',
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            color: color,
            backgroundColor: AppTheme.bgDark,
          ),
        )
      ],
    );
  }
}
