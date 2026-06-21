import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import 'landowner_providers.dart';

class LandownerBookingsTab extends ConsumerWidget {
  const LandownerBookingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(landownerBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondary)),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: AppTheme.error)),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(child: Text('No bookings yet.', style: TextStyle(color: AppTheme.textSecondary)));
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(landownerBookingsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final b = bookings[index];
                final status = b['status'] ?? 'pending';
                final isPending = status == 'pending';
                
                return Card(
                  color: AppTheme.surface,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(b['vehicle_no'] ?? 'Unknown Vehicle', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: status == 'active' ? Colors.green.withOpacity(0.2) : 
                                       status == 'pending' ? Colors.orange.withOpacity(0.2) : 
                                       Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: status == 'active' ? Colors.greenAccent : 
                                         status == 'pending' ? Colors.orangeAccent : 
                                         Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Vehicle Type: ${b['vehicle_type'] ?? 'Car'}', style: const TextStyle(color: AppTheme.textSecondary)),
                        Text('Cost: \$${b['total_cost'] ?? '0.00'}', style: const TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(height: 16),
                        if (isPending)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final repo = ref.read(landownerRepositoryProvider);
                                    await repo.updateBookingStatus(b['id'], 'active');
                                    ref.invalidate(landownerBookingsProvider);
                                    ref.invalidate(analyticsProvider);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                                  child: const Text('Approve', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final repo = ref.read(landownerRepositoryProvider);
                                    await repo.updateBookingStatus(b['id'], 'cancelled');
                                    ref.invalidate(landownerBookingsProvider);
                                  },
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.error)),
                                  child: const Text('Reject', style: TextStyle(color: AppTheme.error)),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
