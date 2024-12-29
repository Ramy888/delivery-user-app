import 'package:cloud_firestore/cloud_firestore.dart';

import 'model_message.dart';

class ModelRequest {
  String reqId;
  String reqAuthor;
  String reqType; //service label from homepage
  String? reqImageUrl; //service image
  String reqDetails;
  String reqExpectedFees;
  String reqVat;
  String reqAppProfit;
  String reqAcceptedDeliveryFees;
  String reqStatus;
  String reqPickUp; // latlng
  List<String>? reqPickUpImages; // Optional
  List<String>? reqDropOffImages; // Optional
  String reqDropOff; // latlng
  String reqCreatedAt;
  String reqUpdatedAt;
  List<ModelMessage>? messagesList; // Optional
  String? expectedArrivalTime;
  String? remainingTime;


  ModelRequest({
    required this.reqId,
    required this.reqAuthor,
    required this.reqType,
    this.reqImageUrl,
    required this.reqDetails,
    required this.reqExpectedFees,
    required this.reqVat,
    required this.reqAppProfit,
    required this.reqAcceptedDeliveryFees,
    required this.reqStatus,
    required this.reqPickUp,
    this.reqPickUpImages,
    this.reqDropOffImages,
    required this.reqDropOff,
    required this.reqCreatedAt,
    required this.reqUpdatedAt,
    this.messagesList,
    this.expectedArrivalTime,
    this.remainingTime,
  });

  /// Factory method to create an empty ModelRequest
  factory ModelRequest.emptyModel() {
    return ModelRequest(
      reqId: '',
      reqType: '',
      reqImageUrl: '',
      reqDetails: '',
      reqAuthor: '',
      reqExpectedFees: '',
      reqVat: '',
      reqAppProfit: '',
      reqAcceptedDeliveryFees: '',
      reqStatus: '',
      reqPickUp: '',
      reqPickUpImages: [],
      reqDropOffImages: [],
      reqDropOff: '',
      reqCreatedAt: '',
      reqUpdatedAt: '',
      expectedArrivalTime: '',
      remainingTime: '',
      messagesList: [],
    );
  }

  /// Convert a JSON map into a ModelRequest instance
  factory ModelRequest.fromJson(Map<String, dynamic> json) {
    return ModelRequest(
      reqId: json['reqId'] ?? '',
      reqAuthor: json['reqAuthor'] ?? '',
      reqType: json['reqType'] ?? '',
      reqImageUrl: json['reqImageUrl'] ?? '',
      reqDetails: json['reqDetails'] ?? '',
      reqExpectedFees: json['reqExpectedFees'] ?? '',
      reqVat: json['reqVat'] ?? '',
      reqAppProfit: json['reqAppProfit'] ?? '',
      reqAcceptedDeliveryFees: json['reqAcceptedDeliveryFees'] ?? '',
      reqStatus: json['reqStatus'] ?? '',
      reqPickUp: json['reqPickUp'] ?? '',
      reqPickUpImages: (json['reqPickUpImages'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      reqDropOffImages: (json['reqDropOffImages'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      reqDropOff: json['reqDropOff'] ?? '',
      reqCreatedAt: json['reqCreatedAt'] ?? '',
      reqUpdatedAt: json['reqUpdatedAt'] ?? '',
      remainingTime: json['remainingTime'] ?? '',
      expectedArrivalTime: json['expectedArrivalTime'] ?? '',
      messagesList: (json['messagesList'] as List<dynamic>?)
          ?.map((e) => ModelMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convert a ModelRequest instance into a JSON map
  Map<String, dynamic> toJson() {
    return {
      'reqId': reqId,
      'reqType': reqType,
      'reqImageUrl': reqImageUrl,
      'reqDetails': reqDetails,
      'reqAuthor': reqAuthor,
      'reqExpectedFees': reqExpectedFees,
      'reqVat': reqVat,
      'reqAppProfit': reqAppProfit,
      'reqAcceptedDeliveryFees': reqAcceptedDeliveryFees,
      'reqStatus': reqStatus,
      'reqPickUp': reqPickUp,
      'reqPickUpImages': reqPickUpImages,
      'reqDropOffImages': reqDropOffImages,
      'reqDropOff': reqDropOff,
      'reqCreatedAt': reqCreatedAt,
      'reqUpdatedAt': reqUpdatedAt,
      'expectedArrivalTime': expectedArrivalTime,
      'remainingTime': remainingTime,
      'messagesList': messagesList?.map((message) => message.toJson()).toList(),
    };
  }

  factory ModelRequest.fromMap(Map<String, dynamic> map) {
    return ModelRequest(
      reqId: map['reqId'] ?? '',
      reqAuthor: map['reqAuthor'] ?? '',
      reqType: map['reqType'] ?? '',
      reqImageUrl: map['reqImageUrl'] ?? '',
      reqDetails: map['reqDetails'] ?? '',
      reqExpectedFees: map['reqExpectedFees'] ?? '',
      reqVat: map['reqVat'] ?? '',
      reqAppProfit: map['reqAppProfit'] ?? '',
      reqAcceptedDeliveryFees: map['reqAcceptedDeliveryFees'] ?? '',
      reqStatus: map['reqStatus'] ?? '',
      reqPickUp: map['reqPickUp'] ?? '',
      remainingTime: map['remainingTime'] ?? '',
      expectedArrivalTime: map['expectedArrivalTime'] ?? '',
      reqPickUpImages: (map['reqPickUpImages'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      reqDropOffImages: (map['reqDropOffImages'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      reqDropOff: map['reqDropOff'] ?? '',
      reqCreatedAt: map['reqCreatedAt'] ?? '',
      reqUpdatedAt: map['reqUpdatedAt'] ?? '',
    );
  }

  factory ModelRequest.fromDocumentSnapshot(DocumentSnapshot<Object?> doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw ArgumentError('DocumentSnapshot data is null for reqId: ${doc.id}');
    }

    return ModelRequest(
      reqId: data['reqId'] ?? doc.id, // Fallback to Firestore document ID
      reqAuthor: data['reqAuthor'] ?? '',
      reqType: data['reqType'] ?? '',
      reqImageUrl: data['reqImageUrl'] ?? '',
      reqDetails: data['reqDetails'] ?? '',
      reqExpectedFees: data['reqExpectedFees'] ?? '',
      reqVat: data['reqVat'] ?? '',
      reqAppProfit: data['reqAppProfit'] ?? '',
      reqAcceptedDeliveryFees: data['reqAcceptedDeliveryFees'] ?? '',
      reqStatus: data['reqStatus'] ?? '',
      reqPickUp: data['reqPickUp'] ?? '',
      reqPickUpImages: (data['reqPickUpImages'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      reqDropOffImages: (data['reqDropOffImages'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      reqDropOff: data['reqDropOff'] ?? '',
      reqCreatedAt: data['reqCreatedAt'] ?? '',
      reqUpdatedAt: data['reqUpdatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reqId': reqId,
      'reqAuthor': reqAuthor,
      'reqType': reqType,
      'reqImageUrl': reqImageUrl,
      'reqDetails': reqDetails,
      'reqExpectedFees': reqExpectedFees,
      'reqVat': reqVat,
      'reqAppProfit': reqAppProfit,
      'reqAcceptedDeliveryFees': reqAcceptedDeliveryFees,
      'reqStatus': reqStatus,
      'reqPickUp': reqPickUp,
      'reqPickUpImages': reqPickUpImages ?? [], // Convert List<String>? to List
      'reqDropOffImages': reqDropOffImages ?? [], // Convert List<String>? to List
      'reqDropOff': reqDropOff,
      'reqCreatedAt': reqCreatedAt,
      'reqUpdatedAt': reqUpdatedAt,
    };
  }
}


