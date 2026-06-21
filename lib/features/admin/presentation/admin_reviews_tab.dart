import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import 'admin_providers.dart';

class AdminReviewsTab extends ConsumerStatefulWidget {
  const AdminReviewsTab({super.key});

  @override
  ConsumerState<AdminReviewsTab> createState() => _AdminReviewsTabState();
}

class _AdminReviewsTabState extends ConsumerState<AdminReviewsTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(adminReviewsProvider);
    final riskFilter = ref.watch(adminReviewRiskFilterProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Column(
        children: [
          // Filter Panel
          _buildFilterHeader(context, riskFilter),

          // Reviews List
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.secondary,
              backgroundColor: AppTheme.bgPanel,
              onRefresh: () async {
                ref.invalidate(adminReviewsProvider);
              },
              child: reviewsAsync.when(
                loading: () => _buildSkeletonList(),
                error: (err, stack) => _buildErrorState(),
                data: (reviews) {
                  if (reviews.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return _buildReviewCard(context, review);
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

  Widget _buildFilterHeader(BuildContext context, String currentRisk) {
    return Container(
      color: AppTheme.bgPanel,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (val) {
                    ref.read(adminReviewQueryProvider.notifier).state = val;
                  },
                  decoration: InputDecoration(
                    hintText: 'Search reviews, spot, author...',
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
              // Rescore All button
              Tooltip(
                message: 'Rescore All Reviews via ML Model',
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.psychology_outlined, color: AppTheme.secondary),
                    onPressed: () => _rescoreAllReviews(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildRiskFilterChip('All Reviews', 'all', currentRisk),
              _buildRiskFilterChip('ML Flagged', 'flagged', currentRisk),
              _buildRiskFilterChip('Verified Safe', 'safe', currentRisk),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskFilterChip(String label, String value, String current) {
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
            ref.read(adminReviewRiskFilterProvider.notifier).state = value;
          }
        },
        selectedColor: value == 'flagged' ? AppTheme.error : AppTheme.secondary,
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

  Widget _buildReviewCard(BuildContext context, Map<String, dynamic> review) {
    final int reviewId = review['id'];
    final String spotTitle = review['spot_title'] ?? 'Unknown Spot';
    final String author = review['author_username'] ?? 'Anonymous';
    final double rating = (review['rating'] ?? 0.0).toDouble();
    final String comment = review['comment'] ?? '';
    final bool isFlagged = review['is_flagged'] ?? false;
    final double mlConfidence = (review['ml_confidence'] ?? 0.0).toDouble();

    String timeStr = '';
    try {
      final dt = DateTime.parse(review['created_at']);
      timeStr = '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {}

    return Card(
      color: AppTheme.bgPanel,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isFlagged ? AppTheme.error.withValues(alpha: 0.4) : AppTheme.borderDark,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Spot, Author, Rating
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spotTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('by @$author', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          if (timeStr.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text('•  $timeStr', style: TextStyle(color: AppTheme.textMuted.withOpacity(0.6), fontSize: 12)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Risk Badge
                _buildRiskBadge(isFlagged, mlConfidence),
              ],
            ),
            const SizedBox(height: 10),
            // Stars indicator
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < rating.round() ? Icons.star : Icons.star_border,
                  color: AppTheme.premiumHighlight,
                  size: 16,
                );
              }),
            ),
            const SizedBox(height: 10),
            // Comment
            Text(
              comment.isNotEmpty ? comment : 'No comment provided.',
              style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.borderDark, height: 1),
            const SizedBox(height: 8),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _executeAction(context, reviewId.toString(), 'rescore'),
                  icon: const Icon(Icons.refresh, size: 14, color: AppTheme.secondary),
                  label: const Text('Rescore', style: TextStyle(color: AppTheme.secondary, fontSize: 12)),
                ),
                if (isFlagged) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _executeAction(context, reviewId.toString(), 'mark_safe'),
                    icon: const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.success),
                    label: const Text('Approve Safe', style: TextStyle(color: AppTheme.success, fontSize: 12)),
                  ),
                ],
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _executeAction(context, reviewId.toString(), 'delete'),
                  icon: const Icon(Icons.delete_outline, size: 14, color: AppTheme.error),
                  label: const Text('Delete', style: TextStyle(color: AppTheme.error, fontSize: 12)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBadge(bool isFlagged, double confidence) {
    final int pct = (confidence * 100).round();
    final Color color = isFlagged ? AppTheme.error : AppTheme.success;
    final String text = isFlagged ? 'HIGH RISK ($pct%)' : 'LOW RISK ($pct%)';
    final IconData icon = isFlagged ? Icons.warning_amber_rounded : Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  void _executeAction(BuildContext context, String reviewId, String action) async {
    String confirmationMsg = '';
    if (action == 'delete') {
      confirmationMsg = 'Are you sure you want to permanently delete this review? This action cannot be undone.';
    } else if (action == 'mark_safe') {
      confirmationMsg = 'Mark this review as safe? It will clear the flag score tag.';
    } else {
      confirmationMsg = 'Rescore this review using the ML text analyzer model?';
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgPanel,
        title: Text('${action[0].toUpperCase()}${action.substring(1).replaceAll('_', ' ')} Review?', style: const TextStyle(color: Colors.white)),
        content: Text(confirmationMsg, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'delete' ? AppTheme.error : AppTheme.secondary,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action == 'delete' ? 'Delete' : 'Execute', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.secondary)),
    );

    final success = await ref
        .read(adminReviewsControllerProvider.notifier)
        .reviewAction(reviewId, action);

    if (!context.mounted) return;
    Navigator.pop(context); // Pop spinner

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review action "$action" completed successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to complete review action.')),
      );
    }
  }

  void _rescoreAllReviews(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgPanel,
        title: const Text('Bulk Rescore Reviews?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Do you want to run the ML text evaluation process on ALL reviews in the database? This may take a few moments depending on review volume.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rescore All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

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
            Text('Processing review rescoring...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    final success = await ref
        .read(adminReviewsControllerProvider.notifier)
        .rescoreAllReviews();

    if (!context.mounted) return;
    Navigator.pop(context); // Pop loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All system reviews rescored successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to complete bulk rescoring.')),
      );
    }
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        height: 140,
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
          const Text('Failed to load review logs.', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(adminReviewsProvider),
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
          Icon(Icons.rate_review_outlined, color: AppTheme.textMuted.withOpacity(0.5), size: 48),
          const SizedBox(height: 12),
          const Text('No review logs match the filters.', style: TextStyle(color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
