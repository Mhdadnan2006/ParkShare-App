import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import 'admin_providers.dart';

class SpotModerationList extends ConsumerWidget {
  const SpotModerationList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotsAsync = ref.watch(moderationSpotsProvider);

    return spotsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      error: (error, stack) => const Center(child: Text('Failed to load spots', style: TextStyle(color: Colors.red))),
      data: (spots) {
        if (spots.isEmpty) {
          return const Center(child: Text('No spots need moderation.', style: TextStyle(color: AppTheme.textMuted)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: spots.length,
          itemBuilder: (context, index) {
            final spot = spots[index];
            final bool isFraudImage = spot['is_fraud_image'] == true;
            final bool isFraudText = spot['is_fraud_text'] == true;
            final bool isFlagged = isFraudImage || isFraudText;
            final bool isSuspended = spot['status'] == 'suspended';

            return Card(
              color: AppTheme.bgPanel,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isFlagged ? AppTheme.error.withOpacity(0.5) : AppTheme.borderDark,
                  width: isFlagged ? 1.5 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.secondary.withOpacity(0.1),
                          child: const Icon(Icons.local_parking, color: AppTheme.secondary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                spot['title'] ?? 'Unknown Spot',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'by @${spot['owner'] ?? 'Unknown'}',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSuspended ? AppTheme.error.withOpacity(0.12) : AppTheme.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSuspended ? AppTheme.error.withOpacity(0.35) : AppTheme.success.withOpacity(0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            spot['status']?.toUpperCase() ?? 'UNKNOWN',
                            style: TextStyle(
                              color: isSuspended ? AppTheme.error : AppTheme.success,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: AppTheme.borderDark),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppTheme.textMuted, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            spot['address'] ?? 'No Address',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.attach_money, color: AppTheme.secondary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '\$${spot['price_per_hour'] ?? '0.00'}/hr',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    if (isFlagged) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.error.withOpacity(0.25), width: 0.8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'HEURISTIC / ML FLAGS DETECTED',
                                  style: TextStyle(color: AppTheme.error, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (isFraudImage)
                              const Text(
                                '• IMAGE FRAUD: High confidence image mismatch or stock photo flag.',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            if (isFraudText)
                              const Text(
                                '• TEXT FRAUD: Suspicious keywords or spam listing features flag.',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Spacer(),
                        SizedBox(
                          width: 130,
                          height: 38,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSuspended ? AppTheme.success : AppTheme.error,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () {
                              ref.read(moderationControllerProvider.notifier).toggleSuspension(spot['id'].toString(), !isSuspended);
                            },
                            child: Text(
                              isSuspended ? 'Unsuspend' : 'Suspend',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
