import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eb3at/Localizations/language_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../Bloc/my_orders_logic.dart';
import '../../Bloc/my_orders_state_event.dart';
import '../../CustomWidgets/customized_text.dart';
import '../../Models/model_request.dart';
import '../standard_order_offers_page.dart';
import '../the_chat_page.dart';

class OrderItemCard extends StatefulWidget {
  final DocumentSnapshot originalOrder;
  final String orderId;
  final String orderStatus;
  final String orderTime;
  final int daysSinceOrder;
  final String serviceImageUrl;
  final String serviceName;
  final double serviceRating;
  final String requestDetails;

  final String pickUp;
  final String dropOff;

  const OrderItemCard({
    Key? key,
    required this.originalOrder,
    required this.orderId,
    required this.orderStatus,
    required this.orderTime,
    required this.daysSinceOrder,
    required this.serviceImageUrl,
    required this.serviceName,
    required this.serviceRating,
    required this.requestDetails,
    required this.pickUp,
    required this.dropOff,
  }) : super(key: key);

  @override
  State<OrderItemCard> createState() => _OrderItemCardState();
}

class _OrderItemCardState extends State<OrderItemCard> {
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFFA726);
      case 'processing':
        return const Color(0xFF2196F3);
      case 'cancelled':
        return const Color(0xFFE57373);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getServiceIcon() {
    switch (widget.serviceName.toLowerCase()) {
      case 'supermarket':
        return Icons.shopping_cart_outlined;
      case 'pharmacy':
        return Icons.local_pharmacy_outlined;
      case 'bakery':
        return Icons.bakery_dining_outlined;
      case 'gas':
        return Icons.local_gas_station_outlined;
      case 'meat & chickens':
        return Icons.restaurant_outlined;
      default:
        return Icons.local_mall_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final modelRequest = ModelRequest.fromDocumentSnapshot(widget.originalOrder);

            // Navigate to order details
            if(widget.serviceName == 'lista'){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRequestPage(
                    requestType: widget.serviceName,
                    pickUpLocation: widget.pickUp,
                    dropOffLocation: widget.dropOff,
                    expectedFees: '',
                    reqId: widget.orderId,
                  ),
                ),
              );
            }else{
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => StandardOrderPage(
                      requestId: widget.orderId,
                      requestModel: modelRequest,
                      originalOrder: widget.originalOrder,
                    )
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              _buildHeader(),
              const Padding(
                padding: EdgeInsets.only(left: 10, right: 10),
                child: Divider(height: 1),
              ),
              _buildMainContent(),
              // if (widget.orderStatus.toLowerCase() != 'completed' &&
              //     widget.orderStatus.toLowerCase() != 'cancelled')
              const Padding(
                padding: EdgeInsets.only(left: 10, right: 10),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.orderStatus)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getStatusColor(widget.orderStatus),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          AppText(
                            text: widget.orderStatus,
                            color: _getStatusColor(widget.orderStatus),
                            isBold: true,
                            fontSize: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // if (widget.orderStatus.toLowerCase() != 'completed' &&
              //     widget.orderStatus.toLowerCase() != 'cancelled')
              //   _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    AppText(
                      text: widget.daysSinceOrder == 0
                          ? widget.orderTime
                          : widget.daysSinceOrder == 1
                              ? '1 day ago'
                              : '${widget.daysSinceOrder} days ago',
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ],
                ),
              ),
            ],
          ),
          _buildOrderActions(context),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getServiceIcon(),
              color: _getStatusColor(widget.orderStatus),
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: widget.serviceName,
                    isBold: true,
                    fontSize: 15,
                ),
                const SizedBox(height: 8),
                AppText(
                  text: widget.requestDetails,
                    color: Colors.grey[600],
                    fontSize: 13,
                    height: 1.4,
                  maxLines: 2,
                  overFlow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                _buildOrderId(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderId() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: AppText(
        text: '${getTranslated(context, "order")} #${widget.orderId.substring(3, 11)}',
          color: Colors.grey[600],
          fontSize: 11,
          isBold: true,

      ),
    );
  }

  Widget _buildOrderActions(BuildContext context) {
    if (widget.orderStatus.toLowerCase() == 'completed' ||
        widget.orderStatus.toLowerCase() == 'cancelled') {
      return IconButton(
        icon: const Icon(Icons.refresh_rounded),
        onPressed: () => _showReorderDialog(context),
        color: Colors.blue[600],
        tooltip: 'Reorder',
      );
    }
    return IconButton(
      icon: const Icon(Icons.more_vert),
      onPressed: () => _showOrderOptions(context),
      color: Colors.grey[600],
    );
  }

  void _showReorderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.refresh_rounded, color: Colors.blue[600]),
            const SizedBox(width: 8),
             AppText(
                text:'${getTranslated(context, "reorder")}',
              fontSize: 15,
              isBold: true,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             AppText(
              text: '${getTranslated(context, "sureReorder")}',
                  fontSize: 13,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.serviceImageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 40,
                        height: 40,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: widget.serviceName,
                            isBold: true,
                            fontSize: 14,

                        ),
                        const SizedBox(height: 4),
                        AppText(
                          text: widget.requestDetails,
                            fontSize: 12,
                            color: Colors.grey[600],
                          maxLines: 1,
                          overFlow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: AppText(
              text: '${getTranslated(context, "cancel")}',
                  color: Colors.grey[600],
              fontSize: 13,

            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<OrderBloc>().add(ReorderOrder(widget.originalOrder));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:  AppText(
                      text: '${getTranslated(context, "orderPlaced")}',
                    fontSize: 14,

                  ),
                  backgroundColor: Colors.green[600],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child:  AppText(
                text:'${getTranslated(context, "placeOrder")}',
              fontSize: 14,
              isBold:true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.orderStatus == 'Cancelled' ||
            widget.orderStatus == 'completed')
          TextButton.icon(
            onPressed: () {
              _showReorderDialog(context);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reorder'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue[600],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          )
        else
          TextButton.icon(
            onPressed: () {
              _showCancelDialog(context);
            },
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel Order'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[600],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title:  AppText(
            text:'${getTranslated(context, "cancelOrder")}',
          fontSize: 15,
          isBold: true,
        ),
        content:  AppText(
          text: '${getTranslated(context, "sureCancelOrder")}',
          fontSize: 13,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: AppText(
              text: '${getTranslated(context, "keepIt")}',
                  color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<OrderBloc>().add(CancelOrder(widget.orderId));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child:  AppText(
                text:'${getTranslated(context, "cancel")}',
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderOptions(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Order ID and Time
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        text: '${getTranslated(context, "order")} #${widget.orderId.substring(3, 11)}',
                          fontSize: 15,
                          isBold: true,

                      ),
                      AppText(
                        text: widget.orderTime,
                          color: Colors.grey[600],
                          fontSize: 13,

                      ),
                    ],
                  ),
                  const Divider(height: 24),
                ],
              ),
            ),
            // Order Actions
            _buildOrderAction(
              context,
              icon: Icons.cancel_outlined,
              label: '${getTranslated(context, "cancelOrder")}',
              color: Colors.red[600]!,
              onTap: () {
                Navigator.pop(context); // Close bottom sheet
                _showCancelDialog(context);
              },
            ),
            _buildOrderAction(
              context,
              icon: Icons.support_agent_outlined,
              label: '${getTranslated(context, "contactSupport")}',
              color: primaryColor,
              onTap: () {
                Navigator.pop(context);
                // Implement contact support functionality
                _contactSupport(context);
              },
            ),
            _buildOrderAction(
              context,
              icon: Icons.share_outlined,
              label: '${getTranslated(context, "shareOrder")}',
              color: Colors.grey[700]!,
              onTap: () {
                Navigator.pop(context);
                _shareOrderDetails(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            AppText(
              text: label,
                color: color,
                fontSize: 15,
                isBold: false,
            ),
          ],
        ),
      ),
    );
  }

  void _contactSupport(BuildContext context) {
    // Implementation for contacting support
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Connecting to support...'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'CANCEL',
          onPressed: () {
            // Handle cancel action
          },
        ),
      ),
    );
  }

  void _shareOrderDetails(BuildContext context) {
    final String shareText = '''
Order Details:
ID: #${widget.orderId.substring(0, 8)}
Service: $widget.serviceName
Status: $widget.orderStatus
Time: $widget.orderTime
Details: $widget.requestDetails
''';

    // Implementation for sharing order details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sharing order details...'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
