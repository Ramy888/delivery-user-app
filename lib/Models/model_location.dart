import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPoint {
  final double latitude;
  final double longitude;

  LocationPoint({required this.latitude, required this.longitude});

  LatLng toLatLng() => LatLng(latitude, longitude);
}