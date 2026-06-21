import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme.dart';

class ActiveBookingQrScreen extends StatelessWidget {
  final String bookingId;
  final String spotTitle;
  final String driverUsername;

  const ActiveBookingQrScreen({
    super.key,
    required this.bookingId,
    required this.spotTitle,
    this.driverUsername = '',
  });

  @override
  Widget build(BuildContext context) {
    final normalizedUsername = driverUsername.trim();
    final String qrData = normalizedUsername.isEmpty
        ? 'PS-BOOK-$bookingId'
        : 'PS-BOOK-$bookingId-$normalizedUsername';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Access Pass', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  spotTitle,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Show this QR code to the landowner to gain access to your parking spot.',
                  style: TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 240.0,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 32),
                Text(
                  'Pass Code: $qrData',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 0.5, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Back to Bookings'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
