import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eb3at/Screens/standard_order_offers_page.dart';
import 'package:eb3at/Screens/the_chat_page.dart';
import 'package:eb3at/Screens/map_select_droppOff_pickup.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../API/firestore_operations.dart';
import '../CustomWidgets/customized_text.dart';
import '../CustomWidgets/photo_selection_widget.dart';
import '../Models/model_request.dart';
import '../Notifiers/selected_location_provider.dart';
import '../Utils/shared_prefs.dart';

class NewStandardOrderPage extends StatefulWidget {
  final String requestType;

  NewStandardOrderPage({required this.requestType});

  @override
  _NewStandardOrderPageState createState() => _NewStandardOrderPageState();
}

class _NewStandardOrderPageState extends State<NewStandardOrderPage> {
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();
  double? vat;
  double? profit;
  double? deliveryFees;
  String requDetails = '';
  bool useWallet = false;
  String paymentType = "cash";
  String dropOffAddress = '';
  String userEmail = '';
  String userPhoto = '';
  String userRating = '';
  String requestId = '';
  FireStoreApi _fireStoreApi = FireStoreApi();
  LatLng pickUpLocation = const LatLng(0.0, 0.0);
  LatLng dropOffLocation = const LatLng(0.0, 0.0);
  List<String> _selectedImages = [];

  @override
  void initState() {

    super.initState();
    dev.log("type::${widget.requestType}");
  }

  void _addNewRequest() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    userEmail = (await SharedPreferenceHelper().getUserEmail())!;
    // userPhoto = await SharedPreferenceHelper().retrieveImagePath()!;

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    requestId = "$timestamp-$userEmail";


    ModelRequest modelRequest = ModelRequest(
      reqId: requestId,
      reqType: widget.requestType,
      reqDetails: _detailsController.text,
      reqAuthor: userEmail,
      reqExpectedFees: '',
      reqVat: '',
      reqAppProfit: '',
      reqAcceptedDeliveryFees: '',
      reqPickUp: latLngToString(pickUpLocation),
      reqPickUpImages: [],
      reqDropOff: latLngToString(dropOffLocation),
      reqDropOffImages: [],
      reqStatus: 'pending',
      reqCreatedAt: DateTime.now().millisecondsSinceEpoch.toString(),
      reqUpdatedAt: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    DocumentSnapshot newOrderSnapshot = await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .set(modelRequest.toMap())
        .then((_) => FirebaseFirestore.instance
            .collection('requests')
            .doc(requestId)
            .get());

    if (widget.requestType == 'List Of Items') {
      List<String> imgsUrls = [];

      if (_selectedImages.isNotEmpty) {
        imgsUrls = await _fireStoreApi.uploadImages(context, _selectedImages);
      }

      _fireStoreApi.addMessage(
        requestId: requestId,
        msgText: _detailsController.text,
        msgImagesFilesUrls: imgsUrls,
        // to be modified
        msgType: 'request',
        msgAuthor: userEmail,
        msgCreatedAt: DateTime.now().toString(),
        msgStatus: 'sent',
        userRating: '',
        //changeable variable
        userPhoto: userPhoto,
        userNumberOfRequestsOrDeliveries: '12', //changeable variable
      );
    }

    Navigator.pop(context);
    // ToastUtil.showHideLoading(true);
    // ToastUtil.showHideLoading(false);
    setState(() {
      pickUpLocation = const LatLng(0.0, 0.0);
      dropOffLocation = const LatLng(0.0, 0.0);
    });
    if (widget.requestType == 'List Of Items') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRequestPage(
            requestType: widget.requestType,
            pickUpLocation: latLngToString(pickUpLocation),
            dropOffLocation: latLngToString(dropOffLocation),
            expectedFees: '',
            reqId: requestId,
          ),
        ),
      );
    } else {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => StandardOrderPage(
                  requestId: requestId,
                  requestModel: modelRequest,
                  originalOrder: newOrderSnapshot,
                )),
      );
    }

    // await Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ChatRequestPage(
    //       reqId: requestId,
    //       requestType: widget.requestType,
    //       dropOffLocation: latLngToString(dropOffLocation),
    //       pickUpLocation: latLngToString(pickUpLocation),
    //       expectedFees: '',
    //     ),
    //   ),
    // );
  }

  String latLngToString(LatLng latLng) {
    return '${latLng.latitude},${latLng.longitude}';
  }

  bool _isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Light grayish-blue background
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                ),
                child: FlexibleSpaceBar(
                  title: innerBoxIsScrolled
                      ? const AppText(
                          text: "Request Delivery",
                          color: Colors.black,
                          isBold: true,
                          fontSize: 16,
                        )
                      : null,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://img.freepik.com/free-vector/delivery-service-illustrated_23-2148505081.jpg',
                        // Alternative URLs if needed:
                        // 'https://img.freepik.com/free-vector/flat-design-delivery-service-background_23-2149157081.jpg',
                        // 'https://img.freepik.com/free-vector/delivery-service-with-masks-concept_23-2148498595.jpg',
                        fit: BoxFit.cover,
                      ),
                      // Gradient overlay for better text visibility
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.5),
                            ],
                          ),
                        ),
                      ),
                      // Optional: Add floating elements
                      Positioned(
                        bottom: 60,
                        left: 20,
                        child: AppText(
                          text: "What would you like\ndelivered today?",
                          color: Colors.white,
                          fontSize: 20,
                          isBold: true,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  onPressed: () {
                    // Show delivery info
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ];
        },
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.pin_drop_outlined,
                              size: 20, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          AppText(
                            text: 'Get From',
                            fontSize: 14,
                            isBold: true,
                            color: Colors.orange[700],
                          ),
                        ],
                      ),
                    ),
                    // Location Selector
                    Consumer<LocationProvider>(
                      builder: (context, locationProvider, child) {
                        dropOffLocation =
                            locationProvider.selectedDropOffLocation;
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange[300]!),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MapSelectLocation(type: 'pick'),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.orange.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.location_on,
                                        color: Colors.orange[700],
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AppText(
                                            text: locationProvider
                                                    .dropOffAddress.isEmpty
                                                ? 'Select Pickup Location'
                                                : locationProvider
                                                    .dropOffAddress,
                                            fontSize: 14,
                                            color: locationProvider
                                                    .dropOffAddress.isEmpty
                                                ? Colors.grey[600]
                                                : Colors.black87,
                                            maxLines: 2,
                                            overFlow: TextOverflow.ellipsis,
                                          ),
                                          if (locationProvider
                                              .dropOffAddress.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .edit_location_alt_outlined,
                                                  size: 13,
                                                  color: Colors.orange[400],
                                                ),
                                                const SizedBox(width: 4),
                                                AppText(
                                                  text:
                                                      'Tap to change location',
                                                  fontSize: 11,
                                                  isBold: false,
                                                  color: Colors.grey[600],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Colors.orange[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Drop-off Location
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.home, size: 20, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          AppText(
                            text: 'My Location',
                            fontSize: 14,
                            isBold: true,
                            color: Colors.green[700],
                          ),
                        ],
                      ),
                    ),
                    // Location Selector
                    Consumer<LocationProvider>(
                      builder: (context, locationProvider, child) {
                        pickUpLocation =
                            locationProvider.selectedPickUpLocation;
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green[300]!),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MapSelectLocation(type: 'drop'),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.home,
                                        color: Colors.green[700],
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AppText(
                                            text: locationProvider
                                                    .pickUpAddress.isEmpty
                                                ? 'Select Drop-off Location'
                                                : locationProvider
                                                    .pickUpAddress,
                                            fontSize: 13,
                                            color: locationProvider
                                                    .pickUpAddress.isEmpty
                                                ? Colors.grey[600]
                                                : Colors.black87,
                                            maxLines: 2,
                                            overFlow: TextOverflow.ellipsis,
                                          ),
                                          if (locationProvider
                                              .pickUpAddress.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            AppText(
                                              text: 'Tap to change location',
                                              fontSize: 11,
                                              isBold: false,
                                              color: Colors.grey[600],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // details Input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        border: Border.all(color: Colors.blue[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.description_outlined,
                              size: 20, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          AppText(
                            text: 'Request Details',
                            fontSize: 14,
                            isBold: true,
                            color: Colors.blue[700],
                          ),
                        ],
                      ),
                    ),

                    // TextField
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue[300]!),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: TextField(
                        controller: _detailsController,
                        keyboardType: TextInputType.multiline,
                        maxLines: 5,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: _isArabic(_detailsController.text)
                              ? 'Cairo'
                              : 'Poppins',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Describe your request here...',
                          hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontFamily: _isArabic(_detailsController.text)
                                  ? 'Cairo'
                                  : 'Poppins',
                              fontSize: 14),
                          labelStyle: TextStyle(
                              fontFamily: _isArabic(_detailsController.text)
                                  ? 'Cairo'
                                  : 'Poppins',
                              fontSize: 14),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () => _detailsController.clear(),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                          border: InputBorder.none,
                          filled: true,
                          fillColor: Colors.white,
                          counterText: '${_detailsController.text.length}/500',
                          counterStyle: TextStyle(
                            color: Colors.grey[600],
                            fontFamily: _isArabic(_detailsController.text)
                                ? 'Cairo'
                                : 'Poppins',
                            fontSize: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            requDetails = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (widget.requestType == 'List Of Items')
                  const SizedBox(height: 16),
                if (widget.requestType == 'List Of Items')
                  PhotoSelectionField(
                    onPhotosSelected: (List<String> photos) {
                      // Handle the selected photos
                      setState(() {
                        _selectedImages = photos;
                      });
                    },
                    hintText: 'Add up to 5 photos...',
                    maxPhotos: 5,
                  ),
                const SizedBox(height: 16),
                // Wallet Usage
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: useWallet ? Colors.indigo[50] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          useWallet ? Colors.indigo[300]! : Colors.grey[300]!,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: useWallet
                                    ? Colors.indigo[100]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_rounded,
                                color: useWallet
                                    ? Colors.indigo[700]
                                    : Colors.grey[600],
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  text: "Use Wallet",
                                  fontSize: 14,
                                  isBold: true,
                                  color: useWallet
                                      ? Colors.indigo[700]
                                      : Colors.grey[800],
                                ),
                                AppText(
                                  text: "Pay using your wallet balance",
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 0.9,
                        child: Switch(
                          value: useWallet,
                          onChanged: (value) {
                            setState(() {
                              useWallet = value;
                            });
                          },
                          activeColor: Colors.white,
                          activeTrackColor: Colors.indigo[400],
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey[300],
                          thumbColor: MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.selected)) {
                                return Colors.white;
                              }
                              return Colors.white;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Type Section
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple[300]!, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.payment_rounded,
                              color: Colors.purple[700],
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          AppText(
                            text: "Payment Type",
                            fontSize: 14,
                            isBold: true,
                            color: Colors.purple[700],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  paymentType = "cash";
                                });
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: paymentType == "cash"
                                      ? Colors.purple[100]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: paymentType == "cash"
                                        ? Colors.purple[400]!
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.money,
                                      color: paymentType == "cash"
                                          ? Colors.purple[700]
                                          : Colors.grey[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    AppText(
                                      text: "Cash",
                                      fontSize: paymentType == "cash" ? 13 : 14,
                                      color: paymentType == "cash"
                                          ? Colors.purple[700]
                                          : Colors.grey[600],
                                      isBold:
                                          paymentType == "cash" ? true : false,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  paymentType = "card";
                                });
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: paymentType == "card"
                                      ? Colors.purple[100]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: paymentType == "card"
                                        ? Colors.purple[400]!
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.credit_card,
                                      color: paymentType == "card"
                                          ? Colors.purple[700]
                                          : Colors.grey[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    AppText(
                                      text: "Card",
                                      color: paymentType == "card"
                                          ? Colors.purple[700]
                                          : Colors.grey[600],
                                      fontSize: paymentType == "cash" ? 13 : 14,
                                      isBold:
                                          paymentType == "card" ? true : false,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Coupon Section
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal[300]!, width: 1.5),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showAddCouponSheet(context),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.local_offer_rounded,
                                color: Colors.teal[700],
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppText(
                                text: "Add Coupon",
                                fontSize: 14,
                                isBold: true,
                                color: Colors.teal[700],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal[50],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.teal[400],
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Place Order Button
                Column(
                  children: [
                    // Delivery Cost Container
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText(
                                text: 'Delivery Cost',
                                isBold: false,
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              AppText(
                                text: '5.99 EGP',
                                isBold: false,
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText(
                                text: 'Total Amount',
                                isBold: true,
                                fontSize: 15,
                                color: Colors.blue[700],
                              ),
                              AppText(
                                text: '25.99 EGP',
                                isBold: true,
                                fontSize: 15,
                                color: Colors.blue[700],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.blue[400],
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: AppText(
                                    text:
                                        'Final cost may vary based on delivery distance',
                                    isBold: false,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Place Order Button
                    Container(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _addNewRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Colors.white),
                            SizedBox(width: 8),
                            AppText(
                                text: "Place Order",
                                isBold: true,
                                fontSize: 16,
                                color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow({required IconData icon, required String label}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(width: 8),
            AppText(
              text: label,
              isBold: true,
              fontSize: 16,
            )
          ],
        ),
        const Icon(Icons.arrow_forward_ios, color: Colors.grey),
      ],
    );
  }

  void _showAddCouponSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.local_offer_rounded,
                          color: Colors.teal[700],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      AppText(
                        text: "Add Coupon",
                        fontSize: 17,
                        isBold: true,
                        color: Colors.teal[700],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          Icon(Icons.close, color: Colors.grey[700], size: 20),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coupon Input
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Enter coupon code",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontFamily: _isArabic(_couponController.text)
                            ? 'Cairo'
                            : 'Poppins',
                      ),
                      labelStyle: TextStyle(
                        fontSize: 14,
                        fontFamily: _isArabic(_couponController.text)
                            ? 'Cairo'
                            : 'Poppins',
                      ),
                      prefixIcon: Icon(Icons.confirmation_number_outlined,
                          color: Colors.teal[400]),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _couponController.clear();
                        },
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.teal[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.teal[400]!),
                      ),
                    ),
                    controller: _couponController,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: _isArabic(_couponController.text)
                          ? 'Cairo'
                          : 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Social Media Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: "Get Latest Offers! 🎉",
                          fontSize: 14,
                          isBold: true,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(height: 8),
                        AppText(
                          text:
                              "Follow us on social media for exclusive deals:",
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSocialButton(
                                Icons.whatshot, "X", Colors.black87),
                            _buildSocialButton(
                                Icons.camera_alt, "Instagram", Colors.pink),
                            _buildSocialButton(
                                Icons.facebook, "Facebook", Colors.blue[700]!),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.teal[700]!),
                              ),
                            ),
                          ),
                        );
                        await Future.delayed(const Duration(seconds: 2));
                        Navigator.pop(context); // Close loading
                        Navigator.pop(context); // Close bottom sheet
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_outlined, color: Colors.white),
                          SizedBox(width: 8),
                          AppText(
                            text: "Verify Coupon",
                            fontSize: 14,
                            isBold: true,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Helper method to build social media buttons
  Widget _buildSocialButton(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 3),
          AppText(
            text: label,
            color: color,
            fontSize: 11,
            isBold: false,
          ),
        ],
      ),
    );
  }
}
