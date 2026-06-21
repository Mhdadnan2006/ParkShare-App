import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme.dart';
import '../domain/booking.dart';
import 'driver_providers.dart';

class RouteGuidanceScreen extends ConsumerStatefulWidget {
  final Booking booking;

  const RouteGuidanceScreen({super.key, required this.booking});

  @override
  ConsumerState<RouteGuidanceScreen> createState() => _RouteGuidanceScreenState();
}

class _RouteGuidanceScreenState extends ConsumerState<RouteGuidanceScreen> {
  final MapController _mapController = MapController();
  LatLng? _driverLocation;
  LatLng? _destinationLocation;
  Map<String, dynamic>? _routeData;
  List<LatLng> _polylinePoints = [];
  bool _isLoading = true;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _initRoute();
  }

  LatLng? _parseGps(String coords) {
    if (coords.isEmpty) return null;
    final parts = coords.split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  Future<void> _initRoute() async {
    // 1. Get destination
    _destinationLocation = _parseGps(widget.booking.spot.gpsCoordinates);
    if (_destinationLocation == null) {
      setState(() {
        _isLoading = false;
        _errorMsg = 'Invalid parking spot GPS coordinates.';
      });
      return;
    }

    // 2. Fetch driver location
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _driverLocation = LatLng(position.latitude, position.longitude);
    } catch (e) {
      // Fallback location if permission denied
      _driverLocation = LatLng(_destinationLocation!.latitude - 0.015, _destinationLocation!.longitude - 0.015);
    }

    // 3. Query route GeoJSON from OSRM wrapper api
    try {
      final repo = ref.read(driverRepositoryProvider);
      final route = await repo.getRoute(
        _driverLocation!.latitude,
        _driverLocation!.longitude,
        _destinationLocation!.latitude,
        _destinationLocation!.longitude,
      );

      setState(() {
        _routeData = route;
        _polylinePoints = _extractPolylinePoints(route);
        _isLoading = false;
      });

      // Fit map view bounds
      if (_polylinePoints.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final bounds = LatLngBounds.fromPoints(_polylinePoints);
          _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
        });
      }
    } catch (e) {
      setState(() {
        // Fallback straight line polyline
        _polylinePoints = [_driverLocation!, _destinationLocation!];
        _isLoading = false;
        _errorMsg = 'Routing API failed. Showing direct flight line.';
      });
    }
  }

  List<LatLng> _extractPolylinePoints(Map<String, dynamic> data) {
    List<LatLng> points = [];
    try {
      final coords = data['geojson']?['features']?[0]?['geometry']?['coordinates'] as List?;
      if (coords != null) {
        for (var pt in coords) {
          if (pt is List && pt.length == 2) {
            points.add(LatLng(pt[1] as double, pt[0] as double)); // OSRM uses [lon, lat]
          }
        }
      }
    } catch (e) {
      // Ignore
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final steps = (_routeData?['steps'] as List?) ?? [];
    final distance = _routeData?['summary']?['distance_km']?.toString() ?? '1.5';
    final duration = _routeData?['summary']?['duration_min']?.toString() ?? '8';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('GPS Routing', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : Stack(
              children: [
                // Leaflet Map layer
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _polylinePoints.isNotEmpty ? _polylinePoints.first : const LatLng(0, 0),
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.parkshare.app',
                    ),
                    if (_polylinePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _polylinePoints,
                            strokeWidth: 5.0,
                            color: AppTheme.primaryBlue,
                          )
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (_driverLocation != null)
                          Marker(
                            point: _driverLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 36),
                          ),
                        if (_destinationLocation != null)
                          Marker(
                            point: _destinationLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_on, color: AppTheme.error, size: 36),
                          ),
                      ],
                    )
                  ],
                ),

                // Direction guidelines overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.bgPanel,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border(top: BorderSide(color: AppTheme.borderDark)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ETA & Distance
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.timer, color: AppTheme.primaryBlue, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '$duration min',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Text(
                              '$distance km left',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        if (_errorMsg.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(_errorMsg, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                        ],
                        const Divider(color: AppTheme.borderDark, height: 24),
                        
                        // Turn-by-Turn Steps Summary list
                        const Text(
                          'Turn-by-turn Guidance',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 100,
                          child: steps.isEmpty
                              ? Center(
                                  child: Text(
                                    'Head towards the parking spot.',
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                  ),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: steps.length,
                                  itemBuilder: (context, idx) {
                                    final step = steps[idx];
                                    final instr = step['instruction'] ?? 'Go straight';
                                    final sDist = step['distance_m'] ?? 0.0;

                                    return Container(
                                      width: 200,
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.bgDark,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppTheme.borderDark),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            instr,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            'For ${sDist.toStringAsFixed(0)}m',
                                            style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
