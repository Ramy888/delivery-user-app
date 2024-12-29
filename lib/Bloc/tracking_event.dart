import '../Models/model_location.dart';

abstract class OrderTrackingEvent {}

class StartTracking extends OrderTrackingEvent {
  final String orderId;

  StartTracking({required this.orderId});
}

class UpdateDeliveryLocation extends OrderTrackingEvent {
  final LocationPoint newLocation;

  UpdateDeliveryLocation({required this.newLocation});
}