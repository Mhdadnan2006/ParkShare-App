import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme.dart';
import '../../../core/network.dart';

import 'package:dio/dio.dart';

class BookingScannerScreen extends StatefulWidget {
  final Map<String, dynamic>? spotData;
  const BookingScannerScreen({super.key, this.spotData});

  @override
  State<BookingScannerScreen> createState() => _BookingScannerScreenState();
}

class _BookingScannerScreenState extends State<BookingScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyQrCode(String qrCode) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    _scannerController.stop();

    try {
      final response = await apiClient.dio.post(
        'landowner/verify-qr/',
        data: {'qr_code': qrCode},
      );

      if (mounted) {
        final data = response.data['data'] ?? {};
        final driver = data['driver'] ?? 'Unknown';
        final vehicle = data['vehicle'] ?? 'Unknown';
        final spot = data['spot'] ?? 'Unknown';
        final duration = data['duration'] ?? 'Unknown';
        final checkIn = data['check_in_time'] ?? 'Unknown';

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.bgPanel,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppTheme.success, width: 1.5)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppTheme.success, size: 28),
                SizedBox(width: 8),
                Text('Access Granted', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Booking confirmed. The vehicle is authorized to park.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  const SizedBox(height: 20),
                  _buildInfoRow('Driver', driver, Icons.person_outline),
                  _buildInfoRow('Vehicle', vehicle, Icons.directions_car_outlined),
                  _buildInfoRow('Parking Spot', spot, Icons.local_parking),
                  _buildInfoRow('Cost / Paid', duration, Icons.attach_money),
                  _buildInfoRow('Check-in time', checkIn, Icons.access_time),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close scanner screen
                },
                child: const Text('OK', style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      }
    } catch (e) {
      String errMsg = 'Invalid or expired QR code.';
      if (e is DioException && e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map) {
          errMsg = responseData['error'] ?? responseData['message'] ?? errMsg;
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.bgPanel,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppTheme.error, width: 1.5)),
            title: const Row(
              children: [
                Icon(Icons.cancel_outlined, color: AppTheme.error, size: 28),
                SizedBox(width: 8),
                Text('Access Denied', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(errMsg, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  setState(() => _isProcessing = false);
                  _scannerController.start();
                },
                child: const Text('Scan Again', style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Access Pass', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _verifyQrCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.secondary),
              ),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: const Text(
              'Position the QR code within the frame',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, backgroundColor: Colors.black54),
            ),
          )
        ],
      ),
    );
  }
}
