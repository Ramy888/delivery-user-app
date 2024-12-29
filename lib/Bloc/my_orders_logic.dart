import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eb3at/API/orders_firestore_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as dev;


import 'my_orders_state_event.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderService _orderService;

  OrderBloc(this._orderService) : super(OrdersLoading()) {
    on<LoadOrders>(_onLoadOrders);
    on<CancelOrder>(_onCancelOrder);
    on<ReorderOrder>(_onReorderOrder);

  }

  Future<void> _onLoadOrders(LoadOrders event, Emitter<OrderState> emit) async {
    emit(OrdersLoading());
    try {
      final ordersSnapshot = await _orderService.getOrders(event.userEmail).first;
      if (ordersSnapshot.docs.isEmpty) {
        emit(OrdersLoaded([]));
      } else {
        emit(OrdersLoaded(ordersSnapshot.docs));
      }
    } catch (e) {
      emit(OrderError('Failed to load orders: $e'));
    }
  }

  Future<void> _onCancelOrder(CancelOrder event, Emitter<OrderState> emit) async {
    try {
      await _orderService.cancelOrder(event.orderId);
      emit(OrderCancelled());
    } catch (e) {
      emit(OrderError('Failed to cancel order: $e'));
    }
  }
  Future<void> _onReorderOrder(ReorderOrder event, Emitter<OrderState> emit) async {
    try {
      final originalData = event.originalOrder.data() as Map<String, dynamic>;

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final uMail = originalData['reqAuthor'] as String;
      String requestId = "$timestamp-$uMail";

      // Create new order with original details but new timestamp and status
      final newOrderData = {
        ...originalData,
        'reqStatus': 'pending',
        'reqCreatedAt': DateTime.now().millisecondsSinceEpoch.toString(),
        'reqId': requestId,
      };

      await _orderService.createOrder(reorder: newOrderData, reqId: requestId);


      // Optionally reload orders after creating new order
      final userEmail = originalData['reqAuthor'] as String;
      add(LoadOrders(userEmail));

    } catch (e) {
      emit(OrderError('Failed to reorder: $e'));
    }
  }
}