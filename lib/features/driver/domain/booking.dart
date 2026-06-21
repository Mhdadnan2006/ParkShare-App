import '../../landowner/domain/parking_spot.dart';

class Booking {
  final int id;
  final ParkingSpot spot;
  final String vehicleNo;
  final String vehicleType;
  final DateTime startTime;
  final DateTime endTime;
  final double totalCost;
  final String status;
  final String? qrCodeUrl;
  final String? licenseImageUrl;
  final String driverName;

  Booking({
    required this.id,
    required this.spot,
    required this.vehicleNo,
    required this.vehicleType,
    required this.startTime,
    required this.endTime,
    required this.totalCost,
    required this.status,
    this.qrCodeUrl,
    this.licenseImageUrl,
    required this.driverName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? 0,
      spot: ParkingSpot.fromJson(json['spot_details'] ?? json['spot'] ?? {}),
      vehicleNo: json['vehicle_no'] ?? '',
      vehicleType: json['vehicle_type'] ?? 'Car',
      startTime: DateTime.tryParse(json['start_time'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['end_time'] ?? '') ?? DateTime.now().add(const Duration(hours: 1)),
      totalCost: double.tryParse(json['total_cost']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'pending',
      qrCodeUrl: json['qr_code'],
      licenseImageUrl: json['license_image'],
      driverName: json['driver_name'] ?? '',
    );
  }
}

