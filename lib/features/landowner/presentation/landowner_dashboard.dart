import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import 'landowner_providers.dart';
import 'spot_management_list.dart';
import 'booking_scanner_screen.dart';
import 'landowner_bookings_list.dart';
import 'landowner_profile_tab.dart';
import 'landowner_messages_tab.dart';

class LandownerDashboard extends ConsumerStatefulWidget {
  const LandownerDashboard({super.key});

  @override
  ConsumerState<LandownerDashboard> createState() => _LandownerDashboardState();
}

class _LandownerDashboardState extends ConsumerState<LandownerDashboard> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const SpotManagementList(),
    const LandownerBookingsTab(),
    const LandownerAnalyticsTab(),
    const LandownerMessagesTab(),
    const LandownerProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ParkShare Host', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner), 
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookingScannerScreen()),
              );
            }
          ),
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.secondary,
        unselectedItemColor: AppTheme.textSecondary,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.local_parking), label: 'Spots'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class LandownerAnalyticsTab extends ConsumerWidget {
  const LandownerAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);
    final bookingsAsync = ref.watch(landownerBookingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondary)),
        error: (err, stack) => Center(
          child: Text('Error loading stats: $err', style: const TextStyle(color: AppTheme.error)),
        ),
        data: (data) {
          final revenue = data['total_revenue']?.toString() ?? '0.00';
          final bookingsCount = data['bookings_count']?.toString() ?? '0';
          final peakMonth = data['peak_month'] ?? 'N/A';
          final mostBooked = data['most_booked'] ?? 'N/A';
          
          final activeBookings = data['active_bookings_count'] ?? 0;
          final totalSpots = data['total_spots'] ?? 0;
          final double utilization = totalSpots > 0 ? (activeBookings / totalSpots) : 0.0;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(analyticsProvider);
              ref.invalidate(landownerBookingsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dashboard',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'Real-time overview of your parking hubs',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.secondary.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.show_chart, color: AppTheme.secondary, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Occupancy Utilization Card (Modern glassmorphic layout)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.bgPanel,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.borderDark),
                    boxShadow: AppTheme.premiumShadows,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Live Occupancy Rate',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Current space usage across all hubs',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$activeBookings',
                                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Text(
                                  ' / $totalSpots spots active',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Utilization Circular Ring
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: utilization,
                              strokeWidth: 8,
                              backgroundColor: AppTheme.borderDark,
                              color: AppTheme.secondary,
                            ),
                          ),
                          Text(
                            '${(utilization * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Grid of KPI Metrics (Revenue, Bookings Count, Peak Month, Trends)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildMetricCard(
                      context,
                      'Total Revenue',
                      '\$$revenue',
                      Icons.attach_money,
                      AppTheme.revenueGradient,
                    ),
                    _buildMetricCard(
                      context,
                      'Total Bookings',
                      bookingsCount,
                      Icons.bookmarks_outlined,
                      AppTheme.dashboardGradient,
                    ),
                    _buildMetricCard(
                      context,
                      'Peak Month',
                      peakMonth,
                      Icons.trending_up,
                      AppTheme.analyticsGradient,
                    ),
                    _buildMetricCard(
                      context,
                      'Top Vehicle',
                      mostBooked.toUpperCase(),
                      Icons.directions_car_outlined,
                      AppTheme.primaryHeroGradient,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Recent Activity / Live Bookings section
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),

                bookingsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondary)),
                  error: (e, s) => Text('Error loading activity: $e', style: const TextStyle(color: AppTheme.error)),
                  data: (bookings) {
                    if (bookings.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.bgPanel,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: const Center(
                          child: Text('No bookings activity registered.', style: TextStyle(color: AppTheme.textSecondary)),
                        ),
                      );
                    }

                    // Display up to 3 most recent bookings
                    final recentList = bookings.take(3).toList();
                    return Column(
                      children: recentList.map((b) {
                        final status = b['status'] ?? 'pending';
                        final vehicle = b['vehicle_no'] ?? 'Unknown';
                        final cost = b['total_cost'] ?? '0.00';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.bgPanel,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.secondary.withOpacity(0.1),
                                    child: const Icon(Icons.local_parking, color: AppTheme.secondary),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vehicle,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Type: ${b['vehicle_type'] ?? 'Car'}',
                                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$$cost',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: status == 'active' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: status == 'active' ? Colors.greenAccent : Colors.orangeAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderDark),
        boxShadow: AppTheme.premiumShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: gradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
