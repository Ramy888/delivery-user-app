import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eb3at/Localizations/language_constants.dart';
import 'package:eb3at/Utils/show_toast.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../Models/model_message.dart';

class FireStoreApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new request document in the "requests" collection
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
      'reqAuthor' : reqAuthor,
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

  // Add a message to the "chat" subcollection under a specific request
  Future<void> addMessage({
    required String requestId,
    required String msgType,//requet or offer
    required String msgAuthor,
    String? msgText, // Optional text
    List<String>? msgImagesFilesUrls, // Optional image/files URLs
    required String msgCreatedAt,
    required String msgStatus,

    required String userRating,
    required String userPhoto,
    required String userNumberOfRequestsOrDeliveries,
  }) async {
    // Generate a unique msgId using Firestore
    final String msgId = _firestore.collection('requests').doc(requestId)
        .collection('chat').doc().id;

    // Create a ModelMessage instance
    ModelMessage message = ModelMessage(
      msgId: msgId,
      msgType: msgType,
      msgAuthor: msgAuthor,
      msgText: msgText,
      msgImagesFilesUrls: msgImagesFilesUrls,
      msgCreatedAt: msgCreatedAt,
      msgStatus: msgStatus,
      requestId: requestId,
      userRating: userRating,
      userPhoto: userPhoto,
      userNumberOfRequestsOrDeliveries: userNumberOfRequestsOrDeliveries,
    );

    // Add the message to the Firestore 'chat' subcollection
    await _firestore
        .collection('requests')
        .doc(requestId)
        .collection('chat')
        .doc(msgId) // Optional: Set msgId as the document ID for uniqueness
        .set(message.toJson());

    //update request updated at
    WriteBatch batch = _firestore.batch();
    DocumentReference requestRef = _firestore.collection('requests').doc(requestId);
    batch.update(requestRef, {
    'reqUpdatedAt': DateTime.now().millisecondsSinceEpoch.toString(),});

    await batch.commit();

  }

  Stream<QuerySnapshot> getRequests(String userMail) {
    return _firestore
        .collection('requests')
        .where('reqAuthor', isEqualTo: userMail) // Filter by useremail
        .orderBy('reqUpdatedAt', descending: true) // Order by creation time
        .snapshots();
  }

  // cancel request
  Future<void> cancelOrder(String orderId) async {
    try {
      await _firestore.collection('requests').doc(orderId).update({
        'orderStatus': 'cancelled',
      });
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }


  // Stream chat messages for real-time updates
  Stream<QuerySnapshot> getChatMessages(String requestId) {
    return _firestore
        .collection('requests')
        .doc(requestId)
        .collection('chat')
        .orderBy('msgCreatedAt', descending: true)
        .snapshots();
  }

  Future<void> updateOfferStatus({
    required String requestId,
    required String messageId,
    required String offerStatus, // 'accepted' or 'rejected'
    String? reqVat, // Required for 'accepted' case
    String? reqAcceptedDeliveryFees, // Required for 'accepted' case
    String? reqAppProfit, // Required for 'accepted' case
  }) async {
    WriteBatch batch = _firestore.batch();

    // Reference to the message document in the 'chat' subcollection
    DocumentReference messageRef = _firestore
        .collection('requests')
        .doc(requestId)
        .collection('chat')
        .doc(messageId);

    // Update the 'msgStatus' in the selected message document
    batch.update(messageRef, {'msgStatus': offerStatus});

    // If the offer is 'accepted', update the request document and other offer messages
    if (offerStatus.toLowerCase() == 'accepted') {
      // Update the request document with provided values
      DocumentReference requestRef = _firestore.collection('requests').doc(requestId);
      batch.update(requestRef, {
        'reqVat': reqVat ?? '0.0',
        'reqAcceptedDeliveryFees': reqAcceptedDeliveryFees ?? '0.0',
        'reqAppProfit': reqAppProfit ?? '0.0',
      });

      // Query to find all other messages with msgType = 'offer' and msgStatus not 'rejected'
      QuerySnapshot offerMessagesSnapshot = await _firestore
          .collection('requests')
          .doc(requestId)
          .collection('chat')
          .where('msgType', isEqualTo: 'offer')
          .where('msgStatus', isNotEqualTo: 'rejected')
          .get();

      // Iterate through the documents and update their msgStatus to 'rejected'
      for (QueryDocumentSnapshot doc in offerMessagesSnapshot.docs) {
        if (doc.id != messageId) { // Exclude the accepted message
          batch.update(doc.reference, {'msgStatus': 'rejected'});
        }
      }
    }

    // Commit the batched write
    await batch.commit();
  }


  Future<List<String>> uploadImages(BuildContext context, List<String> imagePaths) async {
    List<String> downloadUrls = [];
    FirebaseStorage storage = FirebaseStorage.instance;

    for (String path in imagePaths) {
      File file = File(path);
      try {
        // Create a unique file name
        String fileName = 'chat_images/${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
        // Upload the file to Firebase Storage
        UploadTask uploadTask = storage.ref(fileName).putFile(file);
        TaskSnapshot snapshot = await uploadTask;
        // Retrieve the download URL
        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      } catch (e) {
        print('Error uploading $path: $e');
        // Handle errors as needed
        ToastUtil.showShortToast("${getTranslated(context, "somethingWrong")}");
      }
    }
    return downloadUrls;
  }
}
