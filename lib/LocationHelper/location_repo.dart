// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Models/model_location.dart';

class LocationService {
  static const String _googleApiKey = ''; // Replace with your API key

  // Initialize location settings
  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Update location every 10 meters
  );

  /// Requests and checks location permissions
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable them.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return true;
  }

  /// Stream of location updates
  Stream<LocationPoint> getLocationStream() async* {
    await _handleLocationPermission();

    await for (final Position position in Geolocator.getPositionStream(
      locationSettings: locationSettings,
    )) {
      yield LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }
  }

  /// Get route between two points using Google Directions API
  Future<List<LatLng>> getRoute({
    required LocationPoint origin,
    required LocationPoint destination,
  }) async {
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=$_googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final List<LatLng> polylinePoints = [];
          final routes = data['routes'] as List;

          if (routes.isNotEmpty) {
            final legs = routes[0]['legs'] as List;

            for (var leg in legs) {
              final steps = leg['steps'] as List;

              for (var step in steps) {
                polylinePoints.add(LatLng(
                  step['start_location']['lat'],
                  step['start_location']['lng'],
                ));
                polylinePoints.add(LatLng(
                  step['end_location']['lat'],
                  step['end_location']['lng'],
                ));
              }
            }
          }

          return polylinePoints;
        } else {
          throw Exception('Failed to get route: ${data['status']}');
        }
      } else {
        throw Exception('Failed to get route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting route: $e');
    }
  }

  /// Get current location
  Future<LocationPoint> getCurrentLocation() async {
    await _handleLocationPermission();

    final position = await Geolocator.getCurrentPosition();
    return LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}