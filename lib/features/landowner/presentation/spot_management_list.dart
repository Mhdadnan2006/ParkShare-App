import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/network.dart';
import 'spot_editor_form.dart';
import 'booking_scanner_screen.dart';
import 'landowner_providers.dart';

class SpotManagementList extends ConsumerWidget {
  const SpotManagementList({super.key});

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Normalize relative path
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '${ApiClient.baseServerUrl}$cleanPath';
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, int spotId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgPanel,
        title: const Text('Delete Listing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete "$title"? This action cannot be undone.', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(spotControllerProvider.notifier).deleteSpot(spotId);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing deleted successfully!'), backgroundColor: AppTheme.success),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete listing.'), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotsAsync = ref.watch(mySpotsProvider);
    final spotState = ref.watch(spotControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: spotsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondary)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 16),
              Text('Failed to load spots: $error', style: const TextStyle(color: AppTheme.error)),
            ],
          ),
        ),
        data: (spots) {
          if (spots.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.refresh(mySpotsProvider.future),
              child: Stack(
                children: [
                  ListView(),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_parking, size: 64, color: AppTheme.textSecondary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text('No spots registered yet.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SpotEditorForm()),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Your First Spot'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(mySpotsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: spots.length,
              itemBuilder: (context, index) {
                final spot = spots[index];
                final imageUrl = _getImageUrl(spot.mainImage);
                final isActive = spot.status == 'active';
                final isSuspended = spot.status == 'suspended';

                return Card(
                  color: AppTheme.bgPanel,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSuspended ? AppTheme.error.withOpacity(0.3) : AppTheme.borderDark, width: 1),
                  ),
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Image / Fallback
                      Stack(
                        children: [
                          if (imageUrl.isNotEmpty)
                            Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 160,
                                decoration: const BoxDecoration(
                                  gradient: AppTheme.analyticsGradient,
                                ),
                                child: const Center(
                                  child: Icon(Icons.broken_image_outlined, color: AppTheme.textSecondary, size: 40),
                                ),
                              ),
                            )
                          else
                            Container(
                              height: 160,
                              decoration: const BoxDecoration(
                                gradient: AppTheme.analyticsGradient,
                              ),
                              child: const Center(
                                child: Icon(Icons.local_parking, color: AppTheme.secondary, size: 48),
                              ),
                            ),
                          // Status Badge
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: spot.status == 'active' ? Colors.green.withOpacity(0.9) :
                                       spot.status == 'pending' ? Colors.orange.withOpacity(0.9) :
                                       AppTheme.error.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                spot.status.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          // Price Badge
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '\$${spot.pricePerHour.toStringAsFixed(2)}/hr',
                                style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spot.title,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: AppTheme.secondary, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    spot.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Hub specs
                            Row(
                              children: [
                                _buildSpecBadge(Icons.directions_car, spot.vehicleType.toUpperCase()),
                                const SizedBox(width: 8),
                                _buildSpecBadge(Icons.grid_view, '${spot.totalSlots} Slots'),
                                const SizedBox(width: 8),
                                _buildSpecBadge(Icons.square_foot, '${spot.areaSqft.toStringAsFixed(0)} sqft'),
                              ],
                            ),
                            
                            if (spot.features.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: spot.features.map((f) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgDark,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.borderDark),
                                  ),
                                  child: Text(
                                    f,
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                )).toList(),
                              ),
                            ],

                            const Divider(color: AppTheme.borderDark, height: 32),

                            // Availability Toggle & Actions Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text('Available', style: TextStyle(color: Colors.white, fontSize: 14)),
                                    const SizedBox(width: 4),
                                    Switch(
                                      value: spot.isAvailable,
                                      activeThumbColor: AppTheme.secondary,
                                      inactiveThumbColor: Colors.grey,
                                      onChanged: (val) async {
                                        await ref.read(spotControllerProvider.notifier).toggleSpotAvailability(spot.id, val);
                                      },
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.qr_code_scanner, color: AppTheme.secondary),
                                      tooltip: 'Scan Pass',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => BookingScannerScreen(spotData: spot.toMap())),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppTheme.accent),
                                      tooltip: 'Edit Listing',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => SpotEditorForm(spotData: spot.toMap())),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                                      tooltip: 'Delete Listing',
                                      onPressed: () => _confirmDelete(context, ref, spot.id, spot.title),
                                    ),
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.secondary,
        foregroundColor: Colors.white,
        elevation: 6,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SpotEditorForm()),
          );
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildSpecBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.borderDark.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.accent, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
