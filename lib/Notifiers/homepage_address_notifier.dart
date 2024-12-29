import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddressProvider extends ChangeNotifier {

  LatLng _selectedAddressLoc = const LatLng(0.0, 0.0);
  String _strAddress = '';

  LatLng get selectedAdressLocation => _selectedAddressLoc;
  String get strAddress => _strAddress;

  void updateAddressLoc(LatLng location) {
    _selectedAddressLoc = location;
    notifyListeners();
  }

  void updateAddressStr(String address) {
    _strAddress = address;
    notifyListeners();
  }
}