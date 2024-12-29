import 'package:app_settings/app_settings.dart';
import 'package:eb3at/Screens/home_page.dart';
import 'package:eb3at/Utils/show_toast.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../API/place_provider_api.dart';
import 'dart:developer' as log;
import 'package:flutter/services.dart';

import '../../../Models/suggestion_model.dart';
import '../../../SearchClasses/address_search.dart';
import '../../../Utils/shared_prefs.dart';
import '../Notifiers/selected_location_provider.dart';
// import 'package:location/location.dart';

class MapSelectLocation extends StatefulWidget {
  final String type;

  MapSelectLocation({required this.type});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapSelectLocation> {
  final String TAG = 'MapSelectLocation';
  GoogleMapController? mapController; // Made nullable
  double? _currentLat;
  double? _currentLong;
  String? country;
  String? government;
  geolocator.Position? myCurrentPosition;
  String? city;
  String? street;
  CameraPosition? _target;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  PlaceApiProvider placeApiProvider = PlaceApiProvider();
  LatLng defaultLondonCoordinates = const LatLng(51.5072, 0.1276);
  TextEditingController textEditingController = TextEditingController();

  // Location location = Location();

  @override
  void initState() {
    _getCurrentLocation(context);
    super.initState();
  }

  Future<void> _getCurrentLocation(BuildContext context) async {
    bool serviceEnabled;
    geolocator.LocationPermission permission;

    permission = await geolocator.Geolocator.checkPermission();
    log.log(TAG, error: 'Permission: $permission');

    if (permission == geolocator.LocationPermission.denied) {
      permission = await geolocator.Geolocator.requestPermission();

      if (permission == geolocator.LocationPermission.denied) {
        // Permissions are denied, show a dialog with more information.
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text("Location Permission"),
            content: Text(
                "It's important to grant location permission to be used in delivery."),
            actions: <Widget>[
              ElevatedButton(
                child: Text('OK'),
                onPressed: () async {
                  Navigator.of(context).pop(); // Dismiss the dialog
                  // Request permission again
                  await geolocator.Geolocator.requestPermission();
                  // Recursive call to check the new permission status and proceed accordingly.
                  await _getCurrentLocation(context);
                },
              ),
            ],
          ),
        );
        return;
      }
    }

    if (permission == geolocator.LocationPermission.deniedForever) {
      // Permissions are denied forever, show a dialog that directs them to the settings page.
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text("Location Permission"),
          content: Text(
              "Location permissions are permanently denied, please open settings and grant location permission."),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Settings'),
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss the dialog
                await AppSettings.openAppSettings();
                // Request permission again
                await geolocator.Geolocator.requestPermission();
                // Recursive call to check the new permission status and proceed accordingly.
                await _getCurrentLocation(context);
              },
            ),
          ],
        ),
      );
      return;
    }
    // Test if location services are enabled.
    serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
    log.log(TAG, error: 'ServiceEnabled: $serviceEnabled');
    if (!serviceEnabled) {
      geolocator.Geolocator.openLocationSettings();
    }

    // When we reach here, permissions are granted and location services are enabled.
    geolocator.Position position =
        await geolocator.Geolocator.getCurrentPosition(
            desiredAccuracy: geolocator.LocationAccuracy.high);
    // setState or any other method to handle the obtained position.
    setState(() {
      _currentLat = position.latitude;
      _currentLong = position.longitude;
      _target =
          CameraPosition(target: LatLng(_currentLat!, _currentLong!), zoom: 16);
    });

    getMarkers(position.latitude, position.longitude);
    _getAddressFromLatLong(position.latitude, position.longitude);

    ToastUtil.showLongToast("Please point to the delivery location on Map");

    // showDialog(
    //   context: context,
    //   builder: (BuildContext context) => AlertDialog(
    //     title: Text("Select Location"),
    //     content: Text(
    //         "Please point to the delivery location on Map"),
    //     actions: <Widget>[
    //       ElevatedButton(
    //         child: Text('Ok'),
    //         onPressed: () async {
    //           Navigator.of(context).pop(); // Dismiss the dialog
    //         },
    //       ),
    //     ],
    //   ),
    // );

    log.log(TAG, error: 'CurrentLocation: $_currentLat, $_currentLong');
  }

  Future<void> _getAddressFromLatLong(double lat, double long) async {
    List<geocoding.Placemark> placemarks =
        await geocoding.placemarkFromCoordinates(lat, long);
    if (placemarks.isNotEmpty) {
      geocoding.Placemark place = placemarks.first;
      setState(() {
        country = place.country;
        government = place.administrativeArea;
        city = place.locality;
        street = place.street;
      });

      if (street!.isNotEmpty) {
        if (widget.type == 'pick') {
          Provider.of<LocationProvider>(context, listen: false)
              .updatePickupAddress('${street}, ${government}');
        } else {
          Provider.of<LocationProvider>(context, listen: false)
              .updateDroppOffAddress('${street}, ${government}');
        }
      } else {

        if (widget.type == 'pick') {
          Provider.of<LocationProvider>(context, listen: false)
              .updatePickupAddress('${city}, ${government}');
        } else {
          Provider.of<LocationProvider>(context, listen: false)
              .updateDroppOffAddress('${city}, ${government}');
        }
      }
    }
  }

  void getMarkers(double lat, double long) {
    MarkerId markerId = MarkerId(lat.toString() + long.toString());
    Marker marker = Marker(
      markerId: markerId,
      draggable: true,
      onDragEnd: (endPosition) {},
      position: LatLng(lat, long),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    );
    setState(() {
      markers = {}; // This clears all markers, you might not want this.
      markers[markerId] = marker;
    });


    if(widget.type == 'pick') {
      Provider.of<LocationProvider>(context, listen: false)
          .updatePickUpLocation(LatLng(lat, long));
    }else{
      Provider.of<LocationProvider>(context, listen: false)
          .updateDropOffLocation(LatLng(lat, long));
    }
  }

  // void _goToMyLocation() async {
  //   var currentLocation = await location.getLocation();
  //
  //   mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
  //     target: LatLng(currentLocation.latitude!, currentLocation.longitude!),
  //     zoom: 14.0,
  //   )));
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Google Map widget
          _target == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _target!,
                  onMapCreated: (GoogleMapController controller) {
                    mapController = (controller);
                  },
                  markers: Set<Marker>.of(markers.values),
                  onTap: (LatLng tapped) async {
                    await _getAddressFromLatLong(
                        tapped.latitude, tapped.longitude);
                    getMarkers(tapped.latitude, tapped.longitude);
                  },
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                  zoomControlsEnabled: false,
                  padding: EdgeInsets.only(
                    top: 100,
                  ),
                ),
          // UI for displaying the search bar and confirm button
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 35),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 8),
                    // Space between Icon and TextField
                    Expanded(
                      child: TextField(
                        controller: textEditingController,
                        readOnly: true,
                        onTap: () async {
                          final Suggestion? result = await showSearch(
                            context: context,
                            delegate: AddressSearch(),
                          );
                          if (result != null) {
                            LatLng latLng =
                                await placeApiProvider.getPlaceDetailFromId(
                              context,
                              result.placeId,
                            );

                            mapController?.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(target: latLng, zoom: 15),
                              ),
                            );
                            _getAddressFromLatLong(
                                latLng.latitude, latLng.longitude);
                            getMarkers(latLng.latitude, latLng.longitude);
                            textEditingController.text = result.description;
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Search for address',
                          hintStyle: TextStyle(
                            fontSize: 14,
                          ),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: ElevatedButton(
                  onPressed: () {
                    if (markers.isNotEmpty) {
                      Navigator.pop(context);
                    } else {
                      ToastUtil.showShortToast(
                          "You should select delivery Location on map");
                    }
                  },
                  child: Text(
                    'CONFIRM LOCATION',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
