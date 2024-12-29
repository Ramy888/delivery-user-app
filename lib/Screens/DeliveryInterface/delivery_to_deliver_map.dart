import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';


class DeliveryOrderPage extends StatefulWidget {
  final String requestId;

  const DeliveryOrderPage({Key? key, required this.requestId}) : super(key: key);

  @override
  _DeliveryOrderPageState createState() => _DeliveryOrderPageState();
}

class _DeliveryOrderPageState extends State<DeliveryOrderPage> {
  GoogleMapController? mapController;
  LatLng? pickupLocation;
  LatLng? dropoffLocation;
  LatLng? currentLocation;
  String? pickupAddress;
  String? dropoffAddress;
  String orderStatus = 'ACCEPTED'; // ACCEPTED, PICKED_UP, ARRIVED, COMPLETED, CANCELLED
  StreamSubscription<Position>? _locationSubscription;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  bool isLoading = true;
  String? customerName;
  String? customerPhone;

  @override
  void initState() {
    super.initState();
    _initializeDelivery();
    _startLocationUpdates();
  }

  Future<void> _initializeDelivery() async {
    // Get request details
    final doc = await FirebaseFirestore.instance
        .collection('requests')
        .doc(widget.requestId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;

      // Parse locations
      final pickupStr = data['reqPickUp'] as String;
      final pickupCoords = _parseLocationString(pickupStr);

      final dropoffStr = data['reqDropOff'] as String;
      final dropoffCoords = _parseLocationString(dropoffStr);

      setState(() {
        pickupLocation = pickupCoords;
        dropoffLocation = dropoffCoords;
        customerName = data['customerName'];
        customerPhone = data['customerPhone'];
        orderStatus = data['status'] ?? 'ACCEPTED';
      });

      await _updateAddresses();
      _updateMapMarkers();
    }

    setState(() {
      isLoading = false;
    });
  }

  LatLng _parseLocationString(String locationStr) {
    final coords = locationStr
        .replaceAll('(', '')
        .replaceAll(')', '')
        .split(',')
        .map((e) => double.parse(e.trim()))
        .toList();
    return LatLng(coords[0], coords[1]);
  }

  void _startLocationUpdates() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });
      _updateDeliveryLocation();
      _updateMapMarkers();
    });
  }

  Future<void> _updateDeliveryLocation() async {
    if (currentLocation == null) return;

    await FirebaseFirestore.instance
        .collection('requests')
        .doc(widget.requestId)
        .collection('chat')
        .where('msgType', isEqualTo: 'offer')
        .where('msgStatus', isEqualTo: 'accepted')
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        snapshot.docs.first.reference.update({
          'currentLocation': '(${currentLocation!.latitude}, ${currentLocation!.longitude})'
        });
      }
    });
  }

  Future<void> _updateOrderStatus(String status) async {
    setState(() {
      orderStatus = status;
    });

    await FirebaseFirestore.instance
        .collection('requests')
        .doc(widget.requestId)
        .update({'status': status});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Order'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              // Show help dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Help'),
                  content: Text('Contact support if you need assistance'),
                  actions: [
                    TextButton(
                      child: Text('OK'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Map view (2/3 of screen)
          Expanded(
            flex: 2,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: pickupLocation ?? LatLng(0, 0),
                zoom: 15,
              ),
              markers: markers,
              polylines: polylines,
              onMapCreated: (controller) {
                mapController = controller;
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          // Order details and actions (1/3 of screen)
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status indicator
                  _buildStatusIndicator(),
                  SizedBox(height: 16),
                  // Address information
                  _buildAddressInfo(),
                  SizedBox(height: 16),
                  // Action buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        orderStatus,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _getStatusColor() {
    switch (orderStatus) {
      case 'ACCEPTED':
        return Colors.blue;
      case 'PICKED_UP':
        return Colors.orange;
      case 'ARRIVED':
        return Colors.green;
      case 'COMPLETED':
        return Colors.green[700]!;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAddressInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer: $customerName',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Pickup: $pickupAddress',
          style: TextStyle(color: Colors.grey[600]),
        ),
        Text(
          'Dropoff: $dropoffAddress',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Call customer button
        IconButton(
          icon: Icon(Icons.phone),
          onPressed: () => _callCustomer(),
        ),
        // Status update button
        ElevatedButton(
          child: Text(_getNextActionText()),
          onPressed: _handleNextAction,
        ),
        // Cancel button
        if (orderStatus != 'COMPLETED' && orderStatus != 'CANCELLED')
          IconButton(
            icon: Icon(Icons.cancel, color: Colors.red),
            onPressed: () => _showCancelDialog(),
          ),
      ],
    );
  }

  String _getNextActionText() {
    switch (orderStatus) {
      case 'ACCEPTED':
        return 'PICKED UP';
      case 'PICKED_UP':
        return 'ARRIVED';
      case 'ARRIVED':
        return 'COMPLETE';
      default:
        return orderStatus;
    }
  }

  void _handleNextAction() {
    switch (orderStatus) {
      case 'ACCEPTED':
        _updateOrderStatus('PICKED_UP');
        break;
      case 'PICKED_UP':
        _updateOrderStatus('ARRIVED');
        break;
      case 'ARRIVED':
        _updateOrderStatus('COMPLETED');
        break;
    }
  }

  Future<void> _callCustomer() async {
    if (customerPhone != null) {
      final Uri phoneUri = Uri(scheme: 'tel', path: customerPhone);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Delivery?'),
        content: Text('Are you sure you want to cancel this delivery?'),
        actions: [
          TextButton(
            child: Text('No'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Yes'),
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus('CANCELLED');
            },
          ),
        ],
      ),
    );
  }

  void _updateMapMarkers() {
    setState(() {
      markers.clear();

      // Add pickup marker
      if (pickupLocation != null) {
        markers.add(Marker(
          markerId: MarkerId('pickup'),
          position: pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ));
      }

      // Add dropoff marker
      if (dropoffLocation != null) {
        markers.add(Marker(
          markerId: MarkerId('dropoff'),
          position: dropoffLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
      }

      // Add current location marker
      if (currentLocation != null) {
        markers.add(Marker(
          markerId: MarkerId('current'),
          position: currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ));
      }
    });
  }

  Future<void> _updateAddresses() async {
    if (pickupLocation != null) {
      try {
        List<Placemark> pickupPlacemarks = await placemarkFromCoordinates(
          pickupLocation!.latitude,
          pickupLocation!.longitude,
        );
        if (pickupPlacemarks.isNotEmpty) {
          setState(() {
            pickupAddress = '${pickupPlacemarks.first.street}, ${pickupPlacemarks.first.locality}';
          });
        }
      } catch (e) {
        print('Error getting pickup address: $e');
      }
    }

    if (dropoffLocation != null) {
      try {
        List<Placemark> dropoffPlacemarks = await placemarkFromCoordinates(
          dropoffLocation!.latitude,
          dropoffLocation!.longitude,
        );
        if (dropoffPlacemarks.isNotEmpty) {
          setState(() {
            dropoffAddress = '${dropoffPlacemarks.first.street}, ${dropoffPlacemarks.first.locality}';
          });
        }
      } catch (e) {
        print('Error getting dropoff address: $e');
      }
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    mapController?.dispose();
    super.dispose();
  }
}