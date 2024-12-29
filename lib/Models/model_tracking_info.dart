import 'delivery_status_enum.dart';
import 'model_location.dart';

class TrackingInfo {
  final LocationPoint pickupLocation;
  final LocationPoint dropOffLocation;
  final LocationPoint? currentLocation;
  final DeliveryStatus status;

  TrackingInfo({
    required this.pickupLocation,
    required this.dropOffLocation,
    this.currentLocation,
    required this.status,
  });
}