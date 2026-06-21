import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../landowner/domain/parking_spot.dart';
import 'spot_detail_screen.dart';
import 'driver_providers.dart';

class _ScoredSpot {
  final ParkingSpot spot;
  final double distanceKm;
  final double score;

  _ScoredSpot({
    required this.spot,
    required this.distanceKm,
    this.score = 0.0,
  });
}

class DriverMapScreen extends ConsumerStatefulWidget {
  const DriverMapScreen({super.key});

  @override
  ConsumerState<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends ConsumerState<DriverMapScreen> {
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(20.5937, 78.9629);
  StreamSubscription<Position>? _positionStreamSubscription;

  // Filter States
  String _searchQuery = '';
  String _selectedVehicleType = 'All';
  double _maxPrice = 500.0;
  String _viewMode = 'map'; // 'map' or 'list'

  @override
  void initState() {
    super.initState();
    _initLocation();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
    
    _mapController.move(_currentLocation, 13.0);
    
    // Update Riverpod provider to trigger search
    ref.read(searchLocationProvider.notifier).updateLocation(position.latitude, position.longitude);

    // Sync GPS capture to backend history
    try {
      await ref.read(driverRepositoryProvider).captureGps(position.latitude, position.longitude);
    } catch (_) {}
  }

  void _startLocationTracking() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // update when moved 50 meters
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        
        // Periodic sync to backend history (non-blocking)
        ref.read(driverRepositoryProvider)
            .captureGps(position.latitude, position.longitude)
            .catchError((_) {});
      }
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // math.pi / 180
    final c = math.cos;
    final a = 0.5 - c((lat2 - lat1) * p)/2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p))/2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  LatLng _parseGps(String coords, LatLng fallback) {
    if (coords.isEmpty) return fallback;
    final parts = coords.split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return fallback;
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgPanel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter Parking Spots', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 24),
                  const Text('Vehicle Type', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: ['All', 'Car', 'Bike', 'Truck'].map((type) {
                      final isSelected = _selectedVehicleType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                _selectedVehicleType = type;
                              });
                              setState(() {
                                _selectedVehicleType = type;
                              });
                            }
                          },
                          labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textMuted),
                          selectedColor: AppTheme.primaryBlue,
                          backgroundColor: AppTheme.bgDark,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Max Price Per Hour', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                      Text('\$${_maxPrice.toStringAsFixed(0)}/hr', style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _maxPrice,
                    min: 10,
                    max: 500,
                    divisions: 49,
                    activeColor: AppTheme.primaryBlue,
                    inactiveColor: AppTheme.borderDark,
                    onChanged: (val) {
                      setModalState(() {
                        _maxPrice = val;
                      });
                      setState(() {
                        _maxPrice = val;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSpotDetails(ParkingSpot spot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgPanel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      spot.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                    ),
                    child: Text(
                      spot.vehicleType.toUpperCase(),
                      style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text(
                spot.address,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RATE', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 1.2)),
                      const SizedBox(height: 2),
                      Text(
                        '\$${spot.pricePerHour.toStringAsFixed(2)}/hr',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SpotDetailScreen(spot: spot),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    ),
                    child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final spotsAsync = ref.watch(searchedSpotsProvider);
    final spotsList = spotsAsync.value ?? [];

    // Filter spots
    final processedSpots = spotsList.where((spot) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!spot.title.toLowerCase().contains(query) && !spot.address.toLowerCase().contains(query)) {
          return false;
        }
      }
      if (_selectedVehicleType != 'All') {
        if (spot.vehicleType.toLowerCase() != _selectedVehicleType.toLowerCase()) {
          return false;
        }
      }
      if (spot.pricePerHour > _maxPrice) {
        return false;
      }
      return true;
    }).map((spot) {
      final spotPos = _parseGps(spot.gpsCoordinates, _currentLocation);
      final dist = _calculateDistance(
        _currentLocation.latitude,
        _currentLocation.longitude,
        spotPos.latitude,
        spotPos.longitude,
      );
      return _ScoredSpot(spot: spot, distanceKm: dist);
    }).toList();

    double maxDistance = 0.1;
    double maxPrice = 0.0;
    for (var entry in processedSpots) {
      if (entry.distanceKm > maxDistance) maxDistance = entry.distanceKm;
      if (entry.spot.pricePerHour > maxPrice) maxPrice = entry.spot.pricePerHour;
    }

    final ratedSpots = processedSpots.map((entry) {
      final distance = entry.distanceKm < 0.1 ? 0.1 : entry.distanceKm;
      final distanceScore = (1 - (distance / maxDistance)) * 5;
      final priceScore = maxPrice > 0 ? (1 - (entry.spot.pricePerHour / maxPrice)) * 5 : 5.0;
      final weightedScore = (distanceScore * 0.45) + (4.0 * 0.4) + (priceScore * 0.15);
      return _ScoredSpot(
        spot: entry.spot,
        distanceKm: entry.distanceKm,
        score: weightedScore,
      );
    }).toList();

    ratedSpots.sort((a, b) => b.score.compareTo(a.score));

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // Content Layer (Map or List View)
          _viewMode == 'map'
              ? FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation,
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.parkshare.app',
                    ),
                    MarkerLayer(
                      markers: ratedSpots.map((entry) {
                        final spot = entry.spot;
                        final position = _parseGps(spot.gpsCoordinates, _currentLocation);
                        return Marker(
                          point: position,
                          width: 45,
                          height: 45,
                          child: GestureDetector(
                            onTap: () => _showSpotDetails(spot),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.bgPanel,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primaryBlue, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withOpacity(0.4),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                              child: const Icon(Icons.local_parking, color: AppTheme.primaryBlue, size: 28),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                )
              : (ratedSpots.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching parking spots found.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 80),
                      itemCount: ratedSpots.length,
                      itemBuilder: (context, index) {
                        final entry = ratedSpots[index];
                        final spot = entry.spot;
                        final scorePercentage = (entry.score * 20).clamp(0.0, 100.0).toStringAsFixed(0);

                        return Card(
                          color: AppTheme.bgPanel,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          child: InkWell(
                            onTap: () => _showSpotDetails(spot),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              spot.title,
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              spot.address,
                                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryBlue.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                                        ),
                                        child: Text(
                                          '$scorePercentage% MATCH',
                                          style: const TextStyle(
                                            color: AppTheme.primaryBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, color: AppTheme.warning, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${entry.distanceKm.toStringAsFixed(2)} km away',
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 16),
                                          const SizedBox(width: 4),
                                          const Text(
                                            '4.0',
                                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.directions_car, color: AppTheme.primaryBlue, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            spot.vehicleType.toUpperCase(),
                                            style: const TextStyle(color: Colors.white, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Divider(color: AppTheme.borderDark, height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '\$${spot.pricePerHour.toStringAsFixed(2)}/hr',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            spot.isAvailable ? Icons.check_circle : Icons.remove_circle,
                                            color: spot.isAvailable ? AppTheme.success : AppTheme.error,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            spot.isAvailable ? 'Available Now' : 'Occupied',
                                            style: TextStyle(
                                              color: spot.isAvailable ? AppTheme.success : AppTheme.error,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )),

          // Floating Search & Filter Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Card(
              color: AppTheme.bgPanel,
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppTheme.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Search parking spots...',
                          hintStyle: TextStyle(color: AppTheme.textMuted),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune, color: AppTheme.primaryBlue),
                      onPressed: _showFilterDialog,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floating Segment Control Toggle
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.bgPanel,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _viewMode = 'map'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: _viewMode == 'map' ? AppTheme.primaryBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.map, color: _viewMode == 'map' ? Colors.white : AppTheme.textMuted, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Map View',
                              style: TextStyle(
                                color: _viewMode == 'map' ? Colors.white : AppTheme.textMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _viewMode = 'list'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: _viewMode == 'list' ? AppTheme.primaryBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: _viewMode == 'list' ? Colors.white : AppTheme.textMuted, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Recommended',
                              style: TextStyle(
                                color: _viewMode == 'list' ? Colors.white : AppTheme.textMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // My Location Button
          if (_viewMode == 'map')
            Positioned(
              bottom: 96,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'my_location_btn',
                backgroundColor: AppTheme.bgPanel,
                onPressed: _initLocation,
                child: const Icon(Icons.my_location, color: AppTheme.primaryBlue),
              ),
            ),

          if (spotsAsync.isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
        ],
      ),
    );
  }
}
