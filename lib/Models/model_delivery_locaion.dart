// delivery_location.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryLocation {
  final String deliveryId;
  final GeoPoint location;
  final String status;
  final Timestamp timestamp;

  DeliveryLocation({
    required this.deliveryId,
    required this.location,
    required this.status,
    required this.timestamp,
  });

  factory DeliveryLocation.fromMap(Map<String, dynamic> map) {
    return DeliveryLocation(
      deliveryId: map['deliveryId'],
      location: map['location'],
      status: map['status'],
      timestamp: map['timestamp'],
    );
  }
}