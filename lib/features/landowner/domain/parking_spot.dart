class ParkingSpot {
  final int id;
  final String title;
  final String address;
  final String vehicleType;
  final double pricePerHour;
  final bool isAvailable;
  final String status;
  final String? mainImage;
  final String gpsCoordinates;
  final double areaSqft;
  final int totalSlots;
  final List<String> features;
  final String? aadharCard;
  final String? landTax;
  final int owner;
  final String ownerName;

  ParkingSpot({
    required this.id,
    required this.title,
    required this.address,
    required this.vehicleType,
    required this.pricePerHour,
    required this.isAvailable,
    required this.status,
    this.mainImage,
    required this.gpsCoordinates,
    required this.areaSqft,
    required this.totalSlots,
    required this.features,
    this.aadharCard,
    this.landTax,
    this.owner = 0,
    this.ownerName = '',
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    // Parse features list safely
    List<String> parsedFeatures = [];
    final rawFeatures = json['features'];
    if (rawFeatures is List) {
      parsedFeatures = rawFeatures.map((e) => e.toString()).toList();
    } else if (rawFeatures is String && rawFeatures.isNotEmpty) {
      parsedFeatures = rawFeatures.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    return ParkingSpot(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      address: json['address'] ?? '',
      vehicleType: json['vehicle_type'] ?? 'car',
      pricePerHour: double.tryParse(json['price_per_hour']?.toString() ?? '0') ?? 0.0,
      isAvailable: json['is_available'] ?? true,
      status: json['status'] ?? 'pending',
      mainImage: json['main_image'],
      gpsCoordinates: json['gps_coordinates'] ?? '',
      areaSqft: double.tryParse(json['area_sqft']?.toString() ?? '0') ?? 0.0,
      totalSlots: json['total_slots'] ?? 1,
      features: parsedFeatures,
      aadharCard: json['aadhar_card'],
      landTax: json['land_tax'],
      owner: json['owner'] ?? 0,
      ownerName: json['owner_name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'address': address,
      'vehicle_type': vehicleType,
      'price_per_hour': pricePerHour,
      'is_available': isAvailable,
      'status': status,
      'main_image': mainImage,
      'gps_coordinates': gpsCoordinates,
      'area_sqft': areaSqft,
      'total_slots': totalSlots,
      'features': features,
      'aadhar_card': aadharCard,
      'land_tax': landTax,
      'owner': owner,
      'owner_name': ownerName,
    };
  }
}
