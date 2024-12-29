import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationProvider extends ChangeNotifier {
  LatLng _selectedPickUpLocation = const LatLng(0.0, 0.0);
  LatLng _selectedDropOffLocation = const LatLng(0.0, 0.0);
  LatLng _selectedUserHomeLocation = const LatLng(0.0, 0.0);
  String _pickUpAddress = '';
  String _dropOffAddress = '';
  String _homeAddress = '';

  LatLng get selectedPickUpLocation => _selectedPickUpLocation;
  LatLng get selectedDropOffLocation => _selectedDropOffLocation;
  LatLng get selectedUserHomeLocation => _selectedUserHomeLocation;
  String get pickUpAddress => _pickUpAddress;
  String get dropOffAddress => _dropOffAddress;
  String get homeAddress => _homeAddress;

  void updatePickUpLocation(LatLng location) {
    _selectedPickUpLocation = location;
    notifyListeners();
  }

  void updateDropOffLocation(LatLng location) {
    _selectedDropOffLocation = location;
    notifyListeners();
  }

  void updatePickupAddress(String address) {
    _pickUpAddress = address;
    notifyListeners();
  }

  void updateDroppOffAddress(String address) {
    _dropOffAddress = address;
    notifyListeners();
  }

  void updateUserHomeAddress(String address) {
    _homeAddress = address;
    notifyListeners();
  }

  void updateHomeLocation(LatLng location) {
    _selectedUserHomeLocation = location;
    notifyListeners();
  }

}
