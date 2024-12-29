import 'dart:async';

import 'package:eb3at/Bloc/tracking_event.dart';
import 'package:eb3at/Bloc/tracking_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../LocationHelper/location_repo.dart';
import '../LocationHelper/order_repo.dart';
import '../Models/model_tracking_info.dart';

class OrderTrackingBloc extends Bloc<OrderTrackingEvent, OrderTrackingState> {
  final LocationService locationService;
  final OrderRepository orderRepository;
  StreamSubscription? _locationSubscription;

  OrderTrackingBloc({
    required this.locationService,
    required this.orderRepository,
  }) : super(OrderTrackingInitial()) {
    on<StartTracking>(_onStartTracking);
    on<UpdateDeliveryLocation>(_onUpdateLocation);
  }

  Future<void> _onStartTracking(
      StartTracking event,
      Emitter<OrderTrackingState> emit,
      ) async {
    emit(OrderTrackingLoading());

    try {
      // Get initial tracking info
      final trackingInfo = await orderRepository.getTrackingInfo(event.orderId);

      // Get route points between pickup and dropoff
      final routePoints = await locationService.getRoute(
        origin: trackingInfo.pickupLocation,
        destination: trackingInfo.dropOffLocation,
      );

      emit(OrderTrackingActive(
        trackingInfo: trackingInfo,
        routePoints: routePoints,
      ));

      // Subscribe to location updates
      _locationSubscription = locationService
          .getLocationStream()
          .listen((location) {
        add(UpdateDeliveryLocation(newLocation: location));
      });
    } catch (e) {
      emit(OrderTrackingError(message: e.toString()));
    }
  }

  Future<void> _onUpdateLocation(
      UpdateDeliveryLocation event,
      Emitter<OrderTrackingState> emit,
      ) async {
    if (state is OrderTrackingActive) {
      final currentState = state as OrderTrackingActive;

      final updatedTrackingInfo = TrackingInfo(
        pickupLocation: currentState.trackingInfo.pickupLocation,
        dropOffLocation: currentState.trackingInfo.dropOffLocation,
        currentLocation: event.newLocation,
        status: currentState.trackingInfo.status,
      );

      emit(OrderTrackingActive(
        trackingInfo: updatedTrackingInfo,
        routePoints: currentState.routePoints,
      ));
    }
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}