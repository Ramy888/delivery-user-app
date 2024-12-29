import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as dev;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../CustomWidgets/customized_text.dart';

class TrackmapScreen extends StatefulWidget {
  final String requestId;

  const TrackmapScreen({
    Key? key,
    required this.requestId,
  }) : super(key: key);

  @override
  _TrackmapScreenState createState() => _TrackmapScreenState();
}

class _TrackmapScreenState extends State<TrackmapScreen>
    with SingleTickerProviderStateMixin {
  bool _mounted = true;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  StreamSubscription<DocumentSnapshot>? _orderSubscription;
  bool _isPickedUp = false;
  bool? _previousPickupState;

  LatLng? pickupLocation;
  LatLng? dropoffLocation;
  LatLng? deliveryLocation;

  DateTime? expectedArrivalTime;
  String? remainingTime;
  String? deliveryPhone;
  String? deliveryAddress;
  BitmapDescriptor? _motorcycleIcon;
  LatLng? _previousLocation;

  AnimationController? _infoAnimationController;
  Animation<double>? _infoAnimation;

  Future<void> _createMotorcycleMarker() async {
    try {
      _motorcycleIcon = await BitmapDescriptor.asset(
          const ImageConfiguration(), 'assets/images/motorcycle.png',
          width: 35, height: 35, imagePixelRatio: 2.5);
      if (_mounted) {
        setState(() {}); // Trigger rebuild if widget is still mounted
      }
    } catch (e) {
      debugPrint('Error creating motorcycle marker: $e');
      // Fallback to default marker if icon creation fails
      _motorcycleIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
  }

  @override
  void initState() {
    super.initState();
    _createMotorcycleMarker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToOrderUpdates();
    });
    // Initialize the animation controller
    _infoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Initialize the animation
    _infoAnimation = CurvedAnimation(
      parent: _infoAnimationController!,
      curve: Curves.easeInOut,
    );

    // Start the animation
    _infoAnimationController!.forward();
  }

  @override
  void dispose() {
    _mounted = false;
    _orderSubscription?.cancel();
    _mapController?.dispose();
    _motorcycleIcon = null;
    _previousLocation = null;
    _infoAnimationController?.dispose();

    super.dispose();
  }

  void _initializeMarkers() {
    _markers.clear();

    if (pickupLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupLocation!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
      );
    }

    if (dropoffLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('drop-off'),
          position: dropoffLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Drop-off Location'),
        ),
      );
    }

    if (deliveryLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: deliveryLocation!,
          icon: _motorcycleIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Delivery Person'),
          // Add rotation based on bearing if you want the motorcycle to point in the direction of movement
          rotation: _calculateBearing(),
          flat: true,
        ),
      );

      if (_mapController != null && _mounted) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(deliveryLocation!),
        );
      }
    }
  }

  // Calculate bearing for motorcycle rotation (optional)
  double _calculateBearing() {
    if (deliveryLocation == null || _previousLocation == null) return 0;

    return _getBearing(
      _previousLocation!.latitude,
      _previousLocation!.longitude,
      deliveryLocation!.latitude,
      deliveryLocation!.longitude,
    );
  }

  // Helper method to calculate bearing between two points
  double _getBearing(
      double startLat, double startLng, double endLat, double endLng) {
    double latitude1 = startLat * pi / 180;
    double latitude2 = endLat * pi / 180;
    double longDiff = (endLng - startLng) * pi / 180;
    double y = sin(longDiff) * cos(latitude2);
    double x = cos(latitude1) * sin(latitude2) -
        sin(latitude1) * cos(latitude2) * cos(longDiff);
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  Future<void> _getPolylineRoute() async {
    if (pickupLocation == null || dropoffLocation == null) return;

    _polylines.clear();

    PolylinePoints polylinePoints = PolylinePoints();

    try {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: '',
        request: PolylineRequest(
          origin: _isPickedUp
              ? PointLatLng(
                  deliveryLocation!.latitude,
                  deliveryLocation!.longitude,
                )
              : PointLatLng(
                  pickupLocation!.latitude,
                  pickupLocation!.longitude,
                ),
          destination: PointLatLng(
            dropoffLocation!.latitude,
            dropoffLocation!.longitude,
          ),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        List<LatLng> polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
        if (_mounted) {
          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                color: Colors.blue,
                points: polylineCoordinates,
                width: 5,
              ),
            );
          });
        }
      }
    } catch (e) {
      dev.log("Error getting polyline route: $e");
    }
  }

  Future<void> _calculateAndUpdateArrivalTime(
      LatLng currentLocation, LatLng destination) async {
    try {
      final String url =
          'https://maps.googleapis.com/maps/api/distancematrix/json?'
          'origins=${currentLocation.latitude},${currentLocation.longitude}&'
          'destinations=${destination.latitude},${destination.longitude}&'
          'mode=driving&'
          'key=';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' &&
            data['rows'][0]['elements'][0]['status'] == 'OK') {
          final int durationInSeconds =
              data['rows'][0]['elements'][0]['duration']['value'];
          final String durationText =
              data['rows'][0]['elements'][0]['duration']['text'];

          final newExpectedArrival =
              DateTime.now().add(Duration(seconds: durationInSeconds));

          if (_mounted) {
            setState(() {
              expectedArrivalTime = newExpectedArrival;
              remainingTime = durationText;
            });
          }

          await FirebaseFirestore.instance
              .collection('requests')
              .doc(widget.requestId)
              .update({
            'expectedArrivalTime': Timestamp.fromDate(newExpectedArrival),
            'remainingTime': durationText,
          });
        }
      }
    } catch (e) {
      dev.log('Error calculating arrival time: $e');
    }
  }

  bool _parseIsPickedUp(dynamic value) {
    if (value == null) return false;

    if (value is bool) return value;

    if (value is String) {
      return value.toLowerCase() == 'true' ||
          value == '1' ||
          value.toLowerCase() == 'yes';
    }

    if (value is num) {
      return value == 1;
    }

    return false;
  }

  void _listenToOrderUpdates() {
    _orderSubscription?.cancel();

    _orderSubscription = FirebaseFirestore.instance
        .collection('requests')
        .doc(widget.requestId)
        .snapshots()
        .listen((snapshot) async {
      if (!_mounted) return;

      if (!snapshot.exists) return;

      try {
        final data = snapshot.data()!;
        final String pickupStr = data['reqPickUp'];
        final String dropoffStr = data['reqDropOff'];

        final pickup = _parseLatLng(pickupStr);
        final dropoff = _parseLatLng(dropoffStr);

        LatLng? newDeliveryLocation = await _getDeliveryLocation();

        if (!_mounted) return;

        bool newPickupState = _parseIsPickedUp(data['isPickedUp']);

        if (_mounted) {
          setState(() {
            //to update Route when delivery picks he order
            _isPickedUp = newPickupState;

            pickupLocation = pickup;
            dropoffLocation = dropoff;
            if (deliveryLocation != null) {
              _previousLocation = deliveryLocation;
            }
            this.deliveryLocation = newDeliveryLocation;
            // If this is the first location update, set previous = current
            if (_previousLocation == null && deliveryLocation != null) {
              _previousLocation = deliveryLocation;
            }
          });
        }

        // Only update polyline if pickup state changed or it's the first update
        if (_previousPickupState != newPickupState) {
          _previousPickupState = newPickupState;
          await _getPolylineRoute();
        }
        // Also update polyline if delivery location changed while in picked up state
        else if (_isPickedUp && deliveryLocation != _previousLocation) {
          await _getPolylineRoute();
        }

        if (deliveryLocation != null && dropoff != null) {
          await _calculateAndUpdateArrivalTime(
            deliveryLocation!,
            dropoff,
          );
        }

        if (deliveryLocation != null) {
          await _updateDeliveryAddress(deliveryLocation!);
        }

        _initializeMarkers(); // Update markers with new position and rotation
      } catch (e) {
        dev.log("Error in _listenToOrderUpdates: $e");
      }
    }, onError: (error) {
      dev.log("Stream error: $error");
    });
  }

  LatLng? _parseLatLng(String coordStr) {
    try {
      List<String> parts = coordStr.split(',');
      if (parts.length != 2) return null;

      double lat = double.parse(parts[0]);
      double lng = double.parse(parts[1]);
      return LatLng(lat, lng);
    } catch (e) {
      dev.log("Error parsing coordinates: $e");
      return null;
    }
  }

  Future<LatLng?> _getDeliveryLocation() async {
    if (!_mounted) return null;

    try {
      final QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .collection('chat')
          .where('msgType', isEqualTo: 'offer')
          .where('msgStatus', isEqualTo: 'accepted')
          .limit(1)
          .get();

      if (!chatSnapshot.docs.isNotEmpty) return null;

      final offerData = chatSnapshot.docs.first.data() as Map<String, dynamic>;
      final String? deliveryLocationStr = offerData['currentLocation'];

      if (deliveryLocationStr == null) return null;

      return _parseLatLng(deliveryLocationStr);
    } catch (e) {
      dev.log("Error getting delivery location: $e");
      return null;
    }
  }

  Future<void> _updateDeliveryAddress(LatLng location) async {
    if (!_mounted) return;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (!_mounted) return;

      if (placemarks.isNotEmpty && _mounted) {
        setState(() {
          deliveryAddress =
              '${placemarks.first.street}, ${placemarks.first.locality}';
        });
      }
    } catch (e) {
      dev.log("Error updating delivery address: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pickupLocation == null) {
      return  Scaffold(
        backgroundColor: Colors.grey[200],
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        title: const AppText(text: 'Track Order', fontSize: 16, isBold: true,),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: _buildControlButton(
              icon: Icons.more_vert,
              onPressed: () => _showOptionsSheet(),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map as the base layer
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: pickupLocation!,
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _initializeMarkers();
              _getPolylineRoute();
            },
            zoomControlsEnabled: false,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // Control Box at the top
          // SafeArea(
          //   child: Align(
          //     alignment: Alignment.topCenter,
          //     child: _buildControlBox(),
          //   ),
          // ),

          // Delivery Info at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 16, // Add some padding from bottom
            child: _buildDeliveryInfo(),
          ),
        ],
      ),

      // GoogleMap(
      //   initialCameraPosition: CameraPosition(
      //     target: pickupLocation!,
      //     zoom: 15,
      //   ),
      //   markers: _markers,
      //   polylines: _polylines,
      //   onMapCreated: (GoogleMapController controller) {
      //     _mapController = controller;
      //     _initializeMarkers();
      //     _getPolylineRoute();
      //   },
      //   myLocationEnabled: true,
      //   myLocationButtonEnabled: true,
      // ),
    );
  }

  Widget _buildDeliveryInfo() {
    return FadeTransition(
      opacity: _infoAnimation!,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current Location Row
            if (deliveryAddress != null)
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Location',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deliveryAddress!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            // Divider
            if (deliveryAddress != null &&
                (remainingTime != null || expectedArrivalTime != null))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  height: 1,
                  color: Colors.grey.withOpacity(0.3),
                ),
              ),

            // Time Information Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Estimated Time
                if (remainingTime != null)
                  Expanded(
                    child: _buildInfoColumn(
                      icon: Icons.timer,
                      iconColor: Colors.orange,
                      title: 'Time to Arrive',
                      value: remainingTime!,
                    ),
                  ),

                // Vertical Divider
                if (remainingTime != null && expectedArrivalTime != null)
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.grey.withOpacity(0.3),
                  ),

                // Expected Arrival
                if (expectedArrivalTime != null)
                  Expanded(
                    child: _buildInfoColumn(
                      icon: Icons.schedule,
                      iconColor: Colors.green,
                      title: 'Expected At',
                      value: DateFormat('hh:mm a').format(expectedArrivalTime!),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// Keep the existing _buildInfoColumn widget as is
  Widget _buildInfoColumn({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Widget _buildControlBox() {
  //   return Container(
  //     margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
  //     padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.1),
  //           spreadRadius: 1,
  //           blurRadius: 5,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //       children: [
  //         _buildControlButton(
  //           icon: Icons.phone,
  //           onPressed: () async {
  //             if (deliveryPhone != null) {
  //               final Uri phoneUri = Uri(scheme: 'tel', path: deliveryPhone);
  //               if (await canLaunchUrl(phoneUri)) {
  //                 await launchUrl(phoneUri);
  //               }
  //             }
  //           },
  //         ),
  //         const SizedBox(width: 16),
  //         _buildControlButton(
  //           icon: Icons.message,
  //           onPressed: () async {
  //             if (deliveryPhone != null) {
  //               final Uri smsUri = Uri(scheme: 'sms', path: deliveryPhone);
  //               if (await canLaunchUrl(smsUri)) {
  //                 await launchUrl(smsUri);
  //               }
  //             }
  //           },
  //         ),
  //         const SizedBox(width: 16),
  //         _buildControlButton(
  //           icon: Icons.more_vert,
  //           onPressed: () => _showOptionsSheet(),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            color: Colors.black,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _showOptionsSheet() {
    showModalBottomSheet(
      showDragHandle: true,
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Call Delivery Person'),
              onTap: () async {
                if (deliveryPhone != null) {
                  final Uri phoneUri = Uri(scheme: 'tel', path: deliveryPhone);
                  if (await canLaunchUrl(phoneUri)) {
                    await launchUrl(phoneUri);
                  }
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Message Delivery Person'),
              onTap: () async {
                if (deliveryPhone != null) {
                  final Uri smsUri = Uri(scheme: 'sms', path: deliveryPhone);
                  if (await canLaunchUrl(smsUri)) {
                    await launchUrl(smsUri);
                  }
                }
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.report_problem_outlined),
              title: const Text('Report Issue'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
