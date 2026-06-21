import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../../../core/theme.dart';
import 'landowner_providers.dart';

class SpotEditorForm extends ConsumerStatefulWidget {
  final Map<String, dynamic>? spotData;

  const SpotEditorForm({super.key, this.spotData});

  @override
  ConsumerState<SpotEditorForm> createState() => _SpotEditorFormState();
}

class _SpotEditorFormState extends ConsumerState<SpotEditorForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _addressController;
  late TextEditingController _priceController;
  late TextEditingController _gpsController;
  late TextEditingController _dimensionsController;
  late TextEditingController _featuresController;
  late String _vehicleType;

  XFile? _mainImage;
  XFile? _aadharCard;
  XFile? _landTax;

  final ImagePicker _picker = ImagePicker();
  bool _isLocating = false;

  final List<String> _vehicleTypes = ['car', 'bike', 'suv', 'ev', 'truck'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.spotData?['title'] ?? '');
    _addressController = TextEditingController(text: widget.spotData?['address'] ?? '');
    _priceController = TextEditingController(text: widget.spotData?['price_per_hour']?.toString() ?? '');
    _gpsController = TextEditingController(text: widget.spotData?['gps_coordinates'] ?? '');
    _dimensionsController = TextEditingController(text: widget.spotData?['area_sqft']?.toString() ?? '');
    
    // Parse features list to string
    final rawFeatures = widget.spotData?['features'];
    String featuresText = '';
    if (rawFeatures is List) {
      featuresText = rawFeatures.join(', ');
    } else if (rawFeatures is String) {
      featuresText = rawFeatures;
    }
    _featuresController = TextEditingController(text: featuresText);
    
    _vehicleType = widget.spotData?['vehicle_type'] ?? 'car';

    // Auto capture GPS on create
    if (widget.spotData == null) {
      _autoCaptureGps();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _gpsController.dispose();
    _dimensionsController.dispose();
    _featuresController.dispose();
    super.dispose();
  }

  Future<void> _autoCaptureGps() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _gpsController.text = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });
    } catch (e) {
      // Fail silently
    } finally {
      setState(() => _isLocating = false);
    }
  }

  Future<void> _pickImage(String type) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (type == 'main') _mainImage = pickedFile;
        if (type == 'aadhar') _aadharCard = pickedFile;
        if (type == 'tax') _landTax = pickedFile;
      });
    }
  }

  Future<void> _saveSpot() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.spotData == null && (_mainImage == null || _aadharCard == null || _landTax == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All images and documents are required for registration.'), backgroundColor: AppTheme.error),
      );
      return;
    }

    final double? price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price must be greater than zero.'), backgroundColor: AppTheme.error),
      );
      return;
    }

    final double? dimensions = double.tryParse(_dimensionsController.text);
    if (dimensions == null || dimensions <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dimensions must be greater than zero.'), backgroundColor: AppTheme.error),
      );
      return;
    }

    // Split features list
    final List<String> featuresList = _featuresController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Prepare FormData using platform-independent bytes uploads
    final map = <String, dynamic>{
      'title': _titleController.text.trim(),
      'address': _addressController.text.trim(),
      'price_per_hour': _priceController.text.trim(),
      'gps_coordinates': _gpsController.text.trim(),
      'area_sqft': _dimensionsController.text.trim(),
      'vehicle_type': _vehicleType,
      'features': featuresList,
    };

    if (_mainImage != null) {
      map['main_image'] = MultipartFile.fromBytes(
        await _mainImage!.readAsBytes(),
        filename: _mainImage!.name,
      );
    }
    if (_aadharCard != null) {
      map['aadhar_card'] = MultipartFile.fromBytes(
        await _aadharCard!.readAsBytes(),
        filename: _aadharCard!.name,
      );
    }
    if (_landTax != null) {
      map['land_tax'] = MultipartFile.fromBytes(
        await _landTax!.readAsBytes(),
        filename: _landTax!.name,
      );
    }

    final formData = FormData.fromMap(map);

    bool success;
    if (widget.spotData == null) {
      success = await ref.read(spotControllerProvider.notifier).createSpot(formData);
    } else {
      success = await ref.read(spotControllerProvider.notifier).updateSpot(widget.spotData!['id'], formData);
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing submitted successfully!'), backgroundColor: AppTheme.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit listing. Verify inputs.'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spotState = ref.watch(spotControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(widget.spotData == null ? 'Register Spot' : 'Edit Spot', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.bgPanel,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Spot Title', prefixIcon: Icon(Icons.title)),
              style: const TextStyle(color: Colors.white),
              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Full Address', prefixIcon: Icon(Icons.location_on)),
              style: const TextStyle(color: Colors.white),
              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _gpsController,
                    decoration: const InputDecoration(
                      labelText: 'GPS Coordinates (Lat, Lng)',
                      prefixIcon: Icon(Icons.map),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isLocating ? null : _autoCaptureGps,
                  style: IconButton.styleFrom(backgroundColor: AppTheme.secondary),
                  icon: _isLocating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.my_location, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Price / hr (\$)', prefixIcon: Icon(Icons.attach_money)),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _dimensionsController,
                    decoration: const InputDecoration(labelText: 'Dimensions (sq ft)', prefixIcon: Icon(Icons.square_foot)),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _vehicleType,
              dropdownColor: AppTheme.bgPanel,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Supported Vehicle Type',
                prefixIcon: Icon(Icons.directions_car),
              ),
              items: _vehicleTypes.map((type) => DropdownMenuItem(
                value: type,
                child: Text(type.toUpperCase()),
              )).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _vehicleType = val);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _featuresController,
              decoration: const InputDecoration(
                labelText: 'Features (Comma separated)',
                hintText: 'CCTV, Gated, Covered, 24/7 Access',
                prefixIcon: Icon(Icons.featured_play_list_outlined),
              ),
              style: const TextStyle(color: Colors.white),
              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            Text('Verification Documentation', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildFilePicker('Upload Main Spot Photo', _mainImage, 'main'),
            const SizedBox(height: 16),
            _buildFilePicker('Upload Aadhar Card', _aadharCard, 'aadhar'),
            const SizedBox(height: 16),
            _buildFilePicker('Upload Land Tax Receipt', _landTax, 'tax'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: spotState.isLoading ? null : _saveSpot,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: spotState.isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit Listing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePicker(String label, XFile? file, String type) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file != null ? 'Selected: ${file.name}' : label,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (file == null)
                  const Text(
                    'Tap Pick Image to select',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _pickImage(type),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.borderDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Pick Image'),
          )
        ],
      ),
    );
  }
}
