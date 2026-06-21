import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/theme.dart';
import '../../../core/network.dart';
import 'active_booking_qr_screen.dart';

class LicenseOcrScreen extends StatefulWidget {
  final String bookingId;

  const LicenseOcrScreen({super.key, required this.bookingId});

  @override
  State<LicenseOcrScreen> createState() => _LicenseOcrScreenState();
}

class _LicenseOcrScreenState extends State<LicenseOcrScreen> {
  File? _imageFile;
  bool _isLoading = false;
  String? _verificationStatus;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _verificationStatus = null;
      });
    }
  }

  Future<void> _verifyLicense() async {
    if (_imageFile == null) return;
    setState(() => _isLoading = true);

    try {
      String fileName = _imageFile!.path.split('/').last;
      FormData formData = FormData.fromMap({
        "booking_id": widget.bookingId,
        "license_image": await MultipartFile.fromFile(_imageFile!.path, filename: fileName),
      });

      // TODO: Replace with the actual OCR verification endpoint
      final response = await apiClient.dio.post('driver/api/verify-license/', data: formData);

      setState(() {
        _isLoading = false;
        _verificationStatus = response.data['success'] == true ? 'Verification Successful' : 'Verification Failed: ${response.data['error']}';
      });
      
      if (response.data['success'] == true) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('License verified successfully!')));
           Navigator.pushReplacement(
             context,
             MaterialPageRoute(
               builder: (context) => ActiveBookingQrScreen(
                 bookingId: widget.bookingId,
                 spotTitle: 'Parking Spot', // Ideally fetched from context
               ),
             ),
           );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _verificationStatus = 'An error occurred during verification.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('License Verification', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload Driver\'s License',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'For security reasons, please upload a clear image of your driver\'s license to verify your booking.',
              style: TextStyle(color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => _pickImage(ImageSource.camera),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.bgPanel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryBlue, width: 2, style: BorderStyle.solid),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 48, color: AppTheme.primaryBlue),
                          SizedBox(height: 8),
                          Text('Tap to take a photo', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            if (_imageFile != null)
              TextButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, color: AppTheme.textPrimary),
                label: const Text('Choose from Gallery', style: TextStyle(color: AppTheme.textPrimary)),
              ),
            const Spacer(),
            if (_verificationStatus != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _verificationStatus!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _verificationStatus!.contains('Successful') ? Colors.green : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: (_imageFile == null || _isLoading) ? null : _verifyLicense,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit for Verification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
