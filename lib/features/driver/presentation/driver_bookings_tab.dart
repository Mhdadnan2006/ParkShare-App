import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import 'driver_providers.dart';
import 'active_booking_qr_screen.dart';
import 'route_guidance_screen.dart';
import 'review_submission_sheet.dart';

class DriverBookingsTab extends ConsumerStatefulWidget {
  const DriverBookingsTab({super.key});

  @override
  ConsumerState<DriverBookingsTab> createState() => _DriverBookingsTabState();
}

class _DriverBookingsTabState extends ConsumerState<DriverBookingsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          color: AppTheme.bgPanel,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryBlue,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: AppTheme.textMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Active Passes'),
              Tab(text: 'History Log'),
            ],
          ),
        ),
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
        error: (err, stack) => Center(
          child: Text('Error loading bookings: $err', style: const TextStyle(color: AppTheme.error)),
        ),
        data: (bookings) {
          final activeList = bookings.where((b) => ['pending', 'active', 'confirmed'].contains(b.status.toLowerCase())).toList();
          final historyList = bookings.where((b) => ['completed', 'cancelled', 'rejected'].contains(b.status.toLowerCase())).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingsList(activeList, isActiveTab: true),
              _buildBookingsList(historyList, isActiveTab: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingsList(List<dynamic> list, {required bool isActiveTab}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: AppTheme.textMuted.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              isActiveTab ? 'No active parking passes.' : 'No booking history recorded.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(myBookingsProvider.future),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final b = list[index];
          final spot = b.spot;
          final status = b.status.toLowerCase();
          final startStr = DateFormat('dd MMM, hh:mm a').format(b.startTime.toLocal());
          final endStr = DateFormat('hh:mm a').format(b.endTime.toLocal());

          return Card(
            color: AppTheme.bgPanel,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.borderDark),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          spot.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'active' || status == 'completed' ? Colors.green.withOpacity(0.15) :
                                 status == 'pending' ? Colors.orange.withOpacity(0.15) :
                                 Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          b.status.toUpperCase(),
                          style: TextStyle(
                            color: status == 'active' || status == 'completed' ? Colors.greenAccent :
                                   status == 'pending' ? Colors.orangeAccent :
                                   Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(spot.address, style: TextStyle(color: AppTheme.textMuted, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const Divider(color: AppTheme.borderDark, height: 24),
                  
                  // Timings & Cost
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TIME FRAME', style: TextStyle(color: AppTheme.textMuted, fontSize: 9, letterSpacing: 1.0)),
                          const SizedBox(height: 4),
                          Text('$startStr - $endStr', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('TOTAL PAID', style: TextStyle(color: AppTheme.textMuted, fontSize: 9, letterSpacing: 1.0)),
                          const SizedBox(height: 4),
                          Text('\$${b.totalCost.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  
                  // Action buttons
                  if (isActiveTab) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ActiveBookingQrScreen(bookingId: b.id.toString(), spotTitle: b.spot.title),
                                ),
                              );
                            },
                            icon: const Icon(Icons.qr_code, size: 18),
                            label: const Text('View Pass'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RouteGuidanceScreen(booking: b),
                                ),
                              );
                            },
                            icon: const Icon(Icons.navigation, size: 18),
                            label: const Text('Navigate'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: AppTheme.borderDark),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (status == 'completed') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => showReviewSheet(context, spot.id.toString(), b.id.toString()),
                        icon: const Icon(Icons.rate_review_outlined, size: 18),
                        label: const Text('Leave Feedback'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          side: const BorderSide(color: AppTheme.primaryBlue),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
