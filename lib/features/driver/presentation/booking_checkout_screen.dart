import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/theme.dart';
import '../../../core/utils/booking_calculator.dart';
import '../../landowner/domain/parking_spot.dart';
import 'driver_providers.dart';
import 'active_booking_qr_screen.dart';

class BookingCheckoutScreen extends ConsumerStatefulWidget {
  final ParkingSpot spot;

  const BookingCheckoutScreen({super.key, required this.spot});

  @override
  ConsumerState<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends ConsumerState<BookingCheckoutScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(hour: TimeOfDay.now().hour + 2, minute: TimeOfDay.now().minute);
  
  XFile? _licenseImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLocalLoading = false;

  double get _calculatedCost {
    return BookingCalculator.calculateCost(
      widget.spot.pricePerHour.toString(),
      _startTime,
      _endTime
    );
  }

  DateTime _getStartDateTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
  }

  DateTime _getEndDateTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _licenseImage = pickedFile;
      });
    }
  }

  void _submitBooking() async {
    if (_licenseImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver\'s License photo is required for security verification.'), backgroundColor: AppTheme.error),
      );
      return;
    }

    final start = _getStartDateTime();
    final end = _getEndDateTime();
    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isLocalLoading = true);

    try {
      final map = <String, dynamic>{
        'spot': widget.spot.id,
        'spot_id': widget.spot.id,
        'start_time': start.toIso8601String(),
        'end_time': end.toIso8601String(),
        'license_image': MultipartFile.fromBytes(
          await _licenseImage!.readAsBytes(),
          filename: _licenseImage!.name,
        ),
      };

      final formData = FormData.fromMap(map);
      final success = await ref.read(bookingControllerProvider.notifier).createBooking(formData);

      if (mounted) {
        setState(() => _isLocalLoading = false);
        if (success) {
          final createdBooking = ref.read(bookingControllerProvider).value;
          if (createdBooking != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ActiveBookingQrScreen(bookingId: createdBooking.id.toString(), spotTitle: createdBooking.spot.title),
              ),
            );
          }
        } else {
          final err = ref.read(bookingControllerProvider).error;
          String errMsg = 'License verification or booking failed.';
          if (err is DioException && err.response != null) {
            errMsg = err.response?.data['error'] ?? err.response?.data['message'] ?? errMsg;
          }
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.bgPanel,
              title: const Text('Booking Rejected', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
              content: Text(errMsg, style: const TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK', style: TextStyle(color: AppTheme.primaryBlue)),
                )
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocalLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('System error during upload: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Reservation Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target Spot Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.bgPanel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.15),
                    radius: 24,
                    child: const Icon(Icons.local_parking, color: AppTheme.primaryBlue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.spot.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(widget.spot.address, style: TextStyle(color: AppTheme.textMuted, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date Picker Card
            const Text('Reservation Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ListTile(
              tileColor: AppTheme.bgPanel,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.borderDark)),
              leading: const Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
              title: Text('${_selectedDate.toLocal()}'.split(' ')[0], style: const TextStyle(color: Colors.white)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
            const SizedBox(height: 20),

            // Time range row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      ListTile(
                        tileColor: AppTheme.bgPanel,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.borderDark)),
                        title: Text(_startTime.format(context), style: const TextStyle(color: Colors.white, fontSize: 14)),
                        onTap: () async {
                          final time = await showTimePicker(context: context, initialTime: _startTime);
                          if (time != null) setState(() => _startTime = time);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('End Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      ListTile(
                        tileColor: AppTheme.bgPanel,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.borderDark)),
                        title: Text(_endTime.format(context), style: const TextStyle(color: Colors.white, fontSize: 14)),
                        onTap: () async {
                          final time = await showTimePicker(context: context, initialTime: _endTime);
                          if (time != null) setState(() => _endTime = time);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // License Upload Box
            const Text('Driver\'s License for OCR Security Check', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgPanel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Column(
                children: [
                  if (_licenseImage != null) ...[
                    const Icon(Icons.check_circle, color: Colors.green, size: 40),
                    const SizedBox(height: 8),
                    Text('Selected: ${_licenseImage!.name}', style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, color: AppTheme.primaryBlue),
                          label: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: AppTheme.borderDark), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library, color: AppTheme.primaryBlue),
                          label: const Text('Pick Gallery', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: AppTheme.borderDark), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Cost Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.analyticsGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimated Cost', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('\$${_calculatedCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLocalLoading ? null : _submitBooking,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLocalLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('Executing OCR Check...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ],
                  )
                : const Text('Verify & Confirm Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

