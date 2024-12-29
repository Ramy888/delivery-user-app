import 'package:eb3at/API/orders_firestore_api.dart';
import 'package:eb3at/Bloc/my_orders_logic.dart';
import 'package:eb3at/Bloc/my_orders_state_event.dart';
import 'package:eb3at/Screens/standard_order_offers_page.dart';
import 'package:eb3at/Screens/the_chat_page.dart';
import 'package:eb3at/Utils/string_to_date_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as dev;

import '../Models/model_request.dart';
import '../Utils/shared_prefs.dart';
import 'MyOrdersWidgets/order_item.dart';

class MyOrdersPage extends StatefulWidget {
  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  Future<String> _getUserEmail() async {
    return await SharedPreferenceHelper().getUserEmail() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getUserEmail(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: Text('No user email found')),
          );
        }

        final userEmail = snapshot.data!;

        return BlocProvider(
          create: (_) => OrderBloc(OrderService())..add(LoadOrders(userEmail)),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                if (state is OrdersLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is OrdersLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      // Dispatch LoadOrders event and wait for it to complete
                      context.read<OrderBloc>().add(LoadOrders(userEmail));
                      // Wait for the state to change to either OrdersLoaded or OrderError
                      await for (final state
                          in context.read<OrderBloc>().stream) {
                        if (state is OrdersLoaded || state is OrderError) {
                          break;
                        }
                      }
                    },
                    child: state.orders.isEmpty
                        ? _buildEmptyListView()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: state.orders.length,
                            itemBuilder: (context, index) {
                              final order = state.orders[index];

                              // List<ModelRequest> modelRequests = state.orders.map((doc) {
                              //   return ModelRequest.fromDocumentSnapshot(doc);
                              // }).toList();

                              // final modelRequest =
                              //     ModelRequest.fromDocumentSnapshot(order);

                              final orderId = order.id;
                              final orderStatus = order['reqStatus'];
                              final daysSinceOrder = DateTime.now()
                                  .difference(
                                      DateTime.fromMillisecondsSinceEpoch(
                                          int.parse(order['reqCreatedAt'])))
                                  .inDays;
                              final dateTimeString = StringToDateUtil
                                  .formatOrderItemDateToRelativeDay(
                                      int.parse(order['reqCreatedAt']));
                              final serviceName = order['reqType'];
                              final requestDetails = order['reqDetails'] ?? '';
                              final pickUp = order['reqPickUp'] ?? '';
                              final dropOff = order['reqDropOff'] ?? '';
                              // final reqExpectedFees = order['reqExpectedFees'] ?? '';

                              return OrderItemCard(
                                orderId: orderId,
                                orderTime: dateTimeString,
                                orderStatus: orderStatus,
                                daysSinceOrder: daysSinceOrder,
                                serviceImageUrl:
                                    'https://example.com/image.jpg',
                                serviceName: serviceName,
                                serviceRating: 4.5,
                                requestDetails: requestDetails,
                                originalOrder: order,
                                pickUp: pickUp,
                                dropOff: dropOff,
                              );
                            },
                          ),
                  );
                } else if (state is OrderError) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<OrderBloc>().add(LoadOrders(userEmail));
                    },
                    child: _buildErrorView(state.message),
                  );
                } else {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<OrderBloc>().add(LoadOrders(userEmail));
                    },
                    child: _buildEmptyListView(),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyListView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No orders yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pull down to refresh',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pull down to try again',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
