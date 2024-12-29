import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eb3at/Models/model_request.dart';
import 'package:eb3at/Screens/trak_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart' as geocoding;


import '../Bloc/offer_bloc.dart';
import '../Bloc/offer_event.dart';
import '../Bloc/offer_state.dart';
import '../CustomWidgets/customized_text.dart';
import '../Localizations/language_constants.dart';
import '../Models/model_message.dart';
import '../Utils/string_to_date_util.dart';

class StandardOrderPage extends StatefulWidget {
  final String requestId;

  // final ModelMessage orderDetails;
  final ModelRequest requestModel;
  final DocumentSnapshot originalOrder;

  const StandardOrderPage({
    super.key,
    required this.requestId,
    // required this.orderDetails,
    required this.requestModel,
    required this.originalOrder,
  });

  @override
  State<StandardOrderPage> createState() => _StandardOrderPageState();
}

class _StandardOrderPageState extends State<StandardOrderPage>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _isOfferActionTaken = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          OfferBloc(widget.requestId)..add(LoadOffers(widget.requestId)),
      child: Scaffold(
        appBar: AppBar(
          title: Text('${getTranslated(context, "order_details")}'),
          elevation: 0,
        ),
        body: Column(
          children: [
            _buildOrderDetailsCard(widget.requestModel),
            Expanded(
              child: BlocBuilder<OfferBloc, OfferState>(
                builder: (context, state) {
                  if (state is OfferLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is OffersLoaded) {
                    if (widget.requestModel.reqStatus == 'pending') {
                      // if (state.acceptedOffer != null) {
                      //   return _buildAcceptedOfferView(state.acceptedOffer!);
                      // }
                      if (state.offers.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // You might want to add an icon here
                              const Icon(
                                Icons.coffee_rounded,
                                size: 48,
                                color: Colors.brown,
                              ),
                              const SizedBox(height: 16),
                              AppText(
                                text: getTranslated(context, "waitOffers")!,
                                fontSize: 16,
                                isBold: false,
                              ),
                            ],
                          ),
                        );
                      }
                      return _buildOffersList(state.offers);
                    }
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.refresh,
                              size: 35,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              // to reorder
                              _showReorderDialog(widget.requestModel, context);
                            },
                          ),
                          const SizedBox(height: 16),
                          AppText(
                            text: getTranslated(context, "cancelledOffer")!,
                            fontSize: 16,
                            isBold: false,
                          ),
                        ],
                      ),
                    );
                  } else if (state is OfferError) {
                    return Center(child: Text(state.message));
                  }
                  return SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsCard(ModelRequest orderDetails) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID and Type Section
            Row(
              children: [
                Expanded(
                  child: AppText(
                    text:
                        '${getTranslated(context, "order")} #${orderDetails.reqId.substring(3, 11)}',
                    fontSize: 15,
                    isBold: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Request Type and Details
            AppText(
              text: orderDetails.reqType ?? '',
              fontSize: 14,
              color: Colors.grey[900],
            ),
            AppText(
              text: orderDetails.reqDetails ?? '',
              fontSize: 13,
              color: Colors.grey[600],
              maxLines: 2,
              overFlow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Pickup Location
            _buildLocationRow(
              label: "${getTranslated(context, "pickUp")}",
              future: _getAddressFromLatLong(orderDetails.reqPickUp),
            ),
            const SizedBox(height: 8),

            // Dropoff Location
            _buildLocationRow(
              label: "${getTranslated(context, "dropOff")}",
              future: _getAddressFromLatLong(orderDetails.reqDropOff),
            ),
            const SizedBox(height: 16),

            // Time Section
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: AppText(
                    text: StringToDateUtil.formatOrderItemDateToRelativeDay(
                        int.parse(orderDetails.reqCreatedAt)),
                    fontSize: 13,
                    color: Colors.grey[600],
                    overFlow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// Helper widget for location rows
  Widget _buildLocationRow({
    required String label,
    required Future<String> future,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 60, // Fixed width for label
          child: AppText(
            text: label,
            fontSize: 12,
          ),
        ),
        Icon(
          Icons.location_on,
          color: label == 'PickUp' ? Colors.orange[700] : Colors.green[700],
          size: 15,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: FutureBuilder<String>(
            future: future,
            builder: (context, snapshot) {
              String displayText = 'Loading...';
              Color textColor = Colors.grey[600]!;

              if (snapshot.hasError) {
                displayText = 'Error loading address';
                textColor = Colors.red;
              } else if (snapshot.hasData) {
                displayText = snapshot.data ?? '';
              }

              return AppText(
                text: displayText,
                fontSize: 12,
                color: textColor,
                maxLines: 1,
                overFlow: TextOverflow.ellipsis,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOffersList(List<ModelMessage> offers) {
    return ListView.builder(
      itemCount: offers.length,
      itemBuilder: (context, index) {
        return SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: EdgeInsets.only(
              left: index.isEven ? 16 : MediaQuery.of(context).size.width / 3,
              right: index.isEven ? MediaQuery.of(context).size.width / 3 : 16,
              bottom: 8,
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align avatar to the bottom
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: offers[index].userPhoto!,
                            width: 50,
                            height: 50,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                Image.asset('assets/images/logo.png'),
                          ),
                        ),
                      ),
                      Center(
                        child: Row(
                          children: [
                            if (offers[index].userRating != null) ...[
                              const Icon(Icons.star,
                                  color: Colors.orange, size: 14),
                              Text(
                                '${offers[index].userRating}',
                                style: const TextStyle(fontSize: 10),
                              ),
                              const SizedBox(width: 10),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  // const SizedBox(width: 10),
                  Expanded(
                    child: _buildDeliveryOfferBubble(context, offers[index]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeliveryOfferBubble(BuildContext context, ModelMessage message) {
    return Container(
      width: MediaQuery.of(context).size.width * 2 / 3,
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: AppText(
              text: StringToDateUtil.formatOrderItemDateToRelativeDay(
                  int.parse(message.msgCreatedAt)),
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
          Row(
            children: [
              AppText(
                text:
                    '${getTranslated(context, "offer")}: ${message.msgText} ${getTranslated(context, "egp")}',
                fontSize: 14,
                isBold: true,
              ),
            ],
          ),
          const SizedBox(height: 15),
          message.msgStatus == 'sent'
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: () => _acceptOffer(message),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: AppText(
                        text: '${getTranslated(context, "accept")}',
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _rejectOffer(message),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: AppText(
                        text: '${getTranslated(context, "reject")}',
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ],
                )
              : message.msgStatus == 'accepted'
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        AppText(
                          text:
                              'Offer Accepted: ${message.msgText} ${getTranslated(context, "egp")}',
                          fontSize: 15,
                          isBold: true,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to map activity
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TrackmapScreen(requestId: message.requestId)
                              ),
                            );
                          },
                          icon: const Icon(Icons.location_on),
                          label: const Text('Track Order'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.grey.shade300,
                        ),
                        child: AppText(
                          text: capitalizeFirstLetter(message.msgStatus),
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  String capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input; // Return the input if it is empty
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  Widget _buildAcceptedOfferView(ModelMessage offer) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 64,
          color: Colors.green,
        ),
        const SizedBox(height: 16),
        AppText(
          text:
              'Offer Accepted: ${offer.msgText} ${getTranslated(context, "egp")}',
          fontSize: 15,
          isBold: true,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            // Navigate to map activity
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => TrackOrderPage(offer: offer),
            //   ),
            // );
          },
          icon: const Icon(Icons.location_on),
          label: const Text('Track Order'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  void _acceptOffer(ModelMessage message) {
    final totalAmount = double.tryParse(message.msgText!) ?? 0.0;

    final double vat = totalAmount * 0.14;
    final double profit = totalAmount * 0.15;
    final double deliveryFees = totalAmount - (vat + profit);

    final String vatString = vat.toStringAsFixed(2);
    final String profitString = profit.toStringAsFixed(2);
    final String deliveryFeesString = deliveryFees.toStringAsFixed(2);

    context.read<OfferBloc>().add(AcceptOffer(message, vatString,
        deliveryFeesString, profitString, widget.requestId));
    setState(() {
      _isOfferActionTaken = true;
    });
  }

  void _rejectOffer(ModelMessage message) {
    context.read<OfferBloc>().add(RejectOffer(message, widget.requestId));
    setState(() {
      _isOfferActionTaken = true;
    });
  }

  Future<String> _getAddressFromLatLong(String coo) async {
    List<String> latLngParts = coo.split(',');
    double lat = double.parse(latLngParts[0]);
    double long = double.parse(latLngParts[1]);

    List<geocoding.Placemark> placemarks =
        await geocoding.placemarkFromCoordinates(lat, long);
    if (placemarks.isNotEmpty) {
      geocoding.Placemark place = placemarks.first;

      if (place.street!.isNotEmpty) {
        return '${place.street}, ${place.administrativeArea}';
      }
      return '${place.locality}, ${place.administrativeArea}';
    }
    return '';
  }

  void _showReorderDialog(ModelRequest modelRequest, BuildContext context) {
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
              text: '${getTranslated(context, "reorder")}',
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
                      modelRequest.reqImageUrl!,
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
                          text: modelRequest.reqType,
                          isBold: true,
                          fontSize: 14,
                        ),
                        const SizedBox(height: 4),
                        AppText(
                          text: modelRequest.reqDetails,
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
            onPressed: () async {
              // context.read<OrderBloc>().add(ReorderOrder(widget.originalOrder));
              final originalData =
                  widget.originalOrder.data() as Map<String, dynamic>;

              final timestamp =
                  DateTime.now().millisecondsSinceEpoch.toString();
              final uMail = originalData['reqAuthor'] as String;
              String newRequestId = "$timestamp-$uMail";

              // Create new order with original details but new timestamp and status
              final newOrderData = {
                ...originalData,
                'reqStatus': 'pending',
                'reqCreatedAt':
                    DateTime.now().millisecondsSinceEpoch.toString(),
                'reqId': newRequestId,
              };

              // await FirebaseFirestore.instance.collection('requests').doc(requestId).set(newOrderData);
              // Save the data and get the new DocumentSnapshot
              DocumentSnapshot newOrderSnapshot = await FirebaseFirestore
                  .instance
                  .collection('requests')
                  .doc(newRequestId)
                  .set(newOrderData)
                  .then((_) => FirebaseFirestore.instance
                      .collection('requests')
                      .doc(newRequestId)
                      .get());

              ModelRequest newModelreq = ModelRequest.fromMap(newOrderData);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: AppText(
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
              Navigator.pop(context);

              //navigate to new order page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => StandardOrderPage(
                          requestId: newRequestId,
                          requestModel: newModelreq,
                          originalOrder: newOrderSnapshot,
                        ),),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: AppText(
              text: '${getTranslated(context, "placeOrder")}',
              fontSize: 14,
              isBold: true,
            ),
          ),
        ],
      ),
    );
  }
}
