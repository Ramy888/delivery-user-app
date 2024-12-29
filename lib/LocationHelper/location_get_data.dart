import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:app_settings/app_settings.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For LatLng
import 'dart:developer' as dev;


class GetLocationDataHelper {

  void Function(double lat, double long, CameraPosition? target)?
      onLocationUpdated;
  void Function(
          String? country, String? government, String? city, String? street)?
      onAddressUpdated;

  GetLocationDataHelper({this.onLocationUpdated, this.onAddressUpdated});

   double? latt;
   double? lngg;

  Future<void> getCurrentLocation(BuildContext context) async {
    bool serviceEnabled;
    geolocator.LocationPermission permission;

    permission = await geolocator.Geolocator.checkPermission();

    if (permission == geolocator.LocationPermission.denied) {
      permission = await geolocator.Geolocator.requestPermission();

      if (permission == geolocator.LocationPermission.denied) {
        await _showPermissionDialog(context);
        return;
      }
    }

    if (permission == geolocator.LocationPermission.deniedForever) {
      await _showSettingsDialog(context);
      return;
    }

    serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await geolocator.Geolocator.openLocationSettings();
      return;
    }

    geolocator.Position position =
        await geolocator.Geolocator.getCurrentPosition(
      desiredAccuracy: geolocator.LocationAccuracy.high,
    );

    double lat = position.latitude;
    double long = position.longitude;
    dev.log("showMe::${lat}  long: $long");
    CameraPosition target = CameraPosition(target: LatLng(lat, long), zoom: 16);

    this.latt = lat;
    this.lngg = long;
    // Callback to update the state
    // if (onLocationUpdated != null) {
      onLocationUpdated!(lat, long, target);
    // }
  }

  Future<void> getAddressFromLatLong(BuildContext context) async {
    await getCurrentLocation(context);

    List<geocoding.Placemark> placemarks =
        await geocoding.placemarkFromCoordinates(this.latt!, this.lngg!);
    if (placemarks.isNotEmpty) {
      geocoding.Placemark place = placemarks.first;

      // Callback to update the state
      // if (onAddressUpdated != null) {
        onAddressUpdated!(
          place.country,
          place.administrativeArea,
          place.locality,
          place.street,
        );
      // }
    }
  }

  Future<void> _showPermissionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Location Permission"),
          content: const Text(
            "It's important to grant location permission to be used in delivery.",
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('OK'),
              onPressed: () async {
                Navigator.of(context).pop();
                await geolocator.Geolocator.requestPermission();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Location Permission"),
          content: const Text(
            "Location permissions are permanently denied, please open settings and grant location permission.",
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                AppSettings.openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }
}
