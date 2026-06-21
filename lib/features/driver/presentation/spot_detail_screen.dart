import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/network.dart';
import '../../landowner/domain/parking_spot.dart';
import 'booking_checkout_screen.dart';

class SpotDetailScreen extends ConsumerWidget {
  final ParkingSpot spot;

  const SpotDetailScreen({super.key, required this.spot});

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '${ApiClient.baseServerUrl}$cleanPath';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = _getImageUrl(spot.mainImage);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Spot Details', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Header
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppTheme.bgPanel,
                border: Border(bottom: BorderSide(color: AppTheme.borderDark)),
              ),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image_outlined, color: AppTheme.textMuted, size: 50),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.local_parking, size: 100, color: AppTheme.primaryBlue),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    spot.title,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  
                  // Price per hour
                  Text(
                    '\$${spot.pricePerHour.toStringAsFixed(2)} per hour',
                    style: const TextStyle(fontSize: 20, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                  ),
                  
                  const Divider(color: AppTheme.borderDark, height: 32),

                  // Address Info
                  const Text(
                    'Location Address',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppTheme.primaryBlue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          spot.address,
                          style: TextStyle(color: AppTheme.textMuted, height: 1.4),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Details summary badges
                  Row(
                    children: [
                      _buildSpecBadge(Icons.directions_car, spot.vehicleType.toUpperCase()),
                      const SizedBox(width: 8),
                      _buildSpecBadge(Icons.grid_view, '${spot.totalSlots} Slots Available'),
                      const SizedBox(width: 8),
                      _buildSpecBadge(Icons.square_foot, '${spot.areaSqft.toStringAsFixed(0)} sqft'),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Dynamic features list
                  const Text(
                    'Amenities & Features',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  if (spot.features.isEmpty)
                    Text('Standard street parking features.', style: TextStyle(color: AppTheme.textMuted))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: spot.features.map((f) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.bgPanel,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: Text(
                          f,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      )).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingCheckoutScreen(spot: spot),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

