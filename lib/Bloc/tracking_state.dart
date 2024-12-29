import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../Models/model_tracking_info.dart';

abstract class OrderTrackingState {}

class OrderTrackingInitial extends OrderTrackingState {}

class OrderTrackingLoading extends OrderTrackingState {}

class OrderTrackingActive extends OrderTrackingState {
  final TrackingInfo trackingInfo;
  final List<LatLng> routePoints;

  OrderTrackingActive({
    required this.trackingInfo,
    required this.routePoints,
  });
}

class OrderTrackingError extends OrderTrackingState {
  final String message;

  OrderTrackingError({required this.message});
}
