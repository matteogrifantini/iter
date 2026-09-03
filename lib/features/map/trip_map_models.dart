import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Point of interest with geographic coordinates and live routing.
class MapPoiLocation {
  const MapPoiLocation({
    required this.id,
    required this.title,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.address,
    this.timeSlot,
  });

  final String id;
  final String title;
  final String category;
  final double latitude;
  final double longitude;
  final String? address;
  final String? timeSlot;

  LatLng get latLng => LatLng(latitude, longitude);

  /// Computes real Haversine distance in meters to another coordinate.
  double distanceTo(MapPoiLocation other) {
    const earthRadius = 6371000.0; // meters
    final dLat = _deg2rad(other.latitude - latitude);
    final dLon = _deg2rad(other.longitude - longitude);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(latitude)) *
            math.cos(_deg2rad(other.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Estimates walking time in minutes based on average 4.5 km/h walking speed.
  int walkingMinutesTo(MapPoiLocation other) {
    final distMeters = distanceTo(other);
    final minutes = (distMeters / 75.0).round(); // ~75 meters per minute
    return math.max(2, minutes);
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180.0);
}

/// Service fetching real coordinates via OpenStreetMap Nominatim and routing via OSRM.
class RealMapService {
  RealMapService({http.Client? httpClient})
    : _client = httpClient ?? http.Client();

  final http.Client _client;

  /// Fetches real coordinates for a place name in a destination via OpenStreetMap Nominatim.
  Future<LatLng?> geocodePlace(String placeName, String destination) async {
    final query = Uri.encodeComponent('$placeName, $destination');
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
    );

    try {
      final response = await _client
          .get(
            url,
            headers: {
              'User-Agent': 'IterTravelApp/1.0 (contact@itertravel.app)',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        if (list.isNotEmpty) {
          final first = list.first as Map<String, dynamic>;
          final lat = double.tryParse(first['lat'] as String? ?? '');
          final lon = double.tryParse(first['lon'] as String? ?? '');
          if (lat != null && lon != null) {
            return LatLng(lat, lon);
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetches real walking route geometry between points from OSRM (Open Source Routing Machine).
  Future<List<LatLng>> fetchWalkingRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return waypoints;

    final coordsStr = waypoints
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/walking/$coordsStr?overview=full&geometries=geojson',
    );

    try {
      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final geometry = routes.first['geometry'] as Map<String, dynamic>?;
          final coordinates = geometry?['coordinates'] as List<dynamic>?;
          if (coordinates != null) {
            return coordinates.map<LatLng>((c) {
              final pair = c as List<dynamic>;
              return LatLng(
                (pair[1] as num).toDouble(),
                (pair[0] as num).toDouble(),
              );
            }).toList();
          }
        }
      }
    } catch (_) {}

    return waypoints;
  }
}
