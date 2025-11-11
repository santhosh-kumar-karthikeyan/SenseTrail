import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class NavigationService {
  // Using OpenStreetMap's free Nominatim API for geocoding
  static const String nominatimUrl = 'https://nominatim.openstreetmap.org';
  
  // Using OSRM (Open Source Routing Machine) for routing
  static const String osrmUrl = 'https://router.project-osrm.org';

  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permission denied');
          return null;
        }
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      print('❌ Location error: $e');
      return null;
    }
  }

  Future<Map<String, double>?> geocodeDestination(String destination) async {
    try {
      final response = await http.get(
        Uri.parse('$nominatimUrl/search?q=$destination&format=json&limit=1'),
        headers: {'User-Agent': 'SenseTrail/1.0'},
      );

      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        if (results.isNotEmpty) {
          return {
            'lat': double.parse(results[0]['lat']),
            'lon': double.parse(results[0]['lon']),
          };
        }
      }
      print('❌ Geocoding failed');
      return null;
    } catch (e) {
      print('❌ Geocoding error: $e');
      return null;
    }
  }

  Future<List<RouteStep>?> getRoute(
    double startLat,
    double startLon,
    double endLat,
    double endLon,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$osrmUrl/route/v1/foot/$startLon,$startLat;$endLon,$endLat?'
          'steps=true&geometries=geojson&overview=full',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok') {
          final steps = data['routes'][0]['legs'][0]['steps'] as List;
          return steps.map((step) => RouteStep.fromJson(step)).toList();
        }
      }
      print('❌ Routing failed');
      return null;
    } catch (e) {
      print('❌ Routing error: $e');
      return null;
    }
  }

  String getDirection(double bearing) {
    // Convert bearing to simple direction
    if (bearing >= 315 || bearing < 45) return 'straight';
    if (bearing >= 45 && bearing < 135) return 'right';
    if (bearing >= 135 && bearing < 225) return 'straight'; // U-turn as straight
    if (bearing >= 225 && bearing < 315) return 'left';
    return 'straight';
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}

class RouteStep {
  final double distance;
  final String instruction;
  final List<double> location;
  final String maneuver;

  RouteStep({
    required this.distance,
    required this.instruction,
    required this.location,
    required this.maneuver,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    final maneuverType = json['maneuver']['type'] ?? 'straight';
    final coords = json['maneuver']['location'] as List;
    
    return RouteStep(
      distance: json['distance'].toDouble(),
      instruction: json['name'] ?? 'Continue',
      location: [coords[1].toDouble(), coords[0].toDouble()], // [lat, lon]
      maneuver: _convertManeuver(maneuverType),
    );
  }

  static String _convertManeuver(String osrmManeuver) {
    if (osrmManeuver.contains('left')) return 'left';
    if (osrmManeuver.contains('right')) return 'right';
    if (osrmManeuver.contains('straight') || osrmManeuver.contains('continue')) {
      return 'straight';
    }
    return 'straight';
  }
}
