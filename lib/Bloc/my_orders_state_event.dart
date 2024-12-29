import 'package:cloud_firestore/cloud_firestore.dart';

abstract class OrderEvent {}

class LoadOrders extends OrderEvent {
  final String userEmail;
  LoadOrders(this.userEmail);
}

class CancelOrder extends OrderEvent {
  final String orderId;
  CancelOrder(this.orderId);
}

abstract class OrderState {}

class OrdersLoading extends OrderState {}

class OrdersLoaded extends OrderState {
  final List<DocumentSnapshot> orders;
  OrdersLoaded(this.orders);
}

class OrderCancelled extends OrderState {}

class OrderError extends OrderState {
  final String message;
  OrderError(this.message);
}

// In my_orders_state_event.dart
class ReorderOrder extends OrderEvent {
  final DocumentSnapshot originalOrder;
  ReorderOrder(this.originalOrder);
}
