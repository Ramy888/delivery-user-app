import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getOrders(String userEmail) {
    dev.log("showOrders:$userEmail");
    return _firestore
        .collection('requests')
        .where('reqAuthor', isEqualTo: userEmail)
        .orderBy('reqUpdatedAt', descending: true)
        .snapshots();
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await _firestore.collection('requests').doc(orderId).update({
        'reqStatus': 'Cancelled',
      });
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  Future<void> createOrder({
    required Map<String, dynamic> reorder,
    required String reqId,
  }) async {

    await _firestore.collection('requests').doc(reqId).set(reorder);
  }

  Future<void> createRequest({
    required String reqId,
    required String reqType,
    required String reqDetails,
    required String reqAuthor,
    required String reqExpectedFees,
    required String reqVat,
    required String reqAppProfit,
    required String reqAcceptedDeliveryFees,
    required String reqPickUp, // latlng
    List<String>? reqPickUpImages,
    List<String>? reqDropOffImages,
    required String reqDropOff, // latlng
  }) async {
    await _firestore.collection('requests').doc(reqId).set({
      'reqId': reqId,
      'reqType': reqType,
      'reqDetails': reqDetails,
      'reqAuthor': reqAuthor,
      'reqExpectedFees': reqExpectedFees,
      'reqVat': reqVat,
      'reqAppProfit': reqAppProfit,
      'reqAcceptedDeliveryFees': reqAcceptedDeliveryFees,
      'reqStatus': 'pending',
      'reqPickUp': reqPickUp,
      'reqPickUpImages': reqPickUpImages ?? [],
      'reqDropOffImages': reqDropOffImages ?? [],
      'reqDropOff': reqDropOff,
      // 'reqCreatedAt': FieldValue.serverTimestamp(),
      'reqCreatedAt': DateTime.now().millisecondsSinceEpoch.toString(),
      'reqUpdatedAt': DateTime.now().millisecondsSinceEpoch.toString(),
      // 'messagesList': [], // Empty list for messages
    });
  }
}
