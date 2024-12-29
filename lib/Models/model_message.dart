class ModelMessage {
  String msgId;
  String msgType; // request or offer
  String? msgDataType; // contains image or contains file
  String msgAuthor;
  String? msgText; // Optional
  List<String>? msgImagesFilesUrls; // Optional: One, more, or none
  String msgCreatedAt;
  String msgStatus;
  String requestId;
  String? userRating; // New: Optional field for user rating
  String? userPhoto;  // New: Optional field for user photo
  String? userNumberOfRequestsOrDeliveries;  // New: Optional field for user photo
  String? currentLocation;


  ModelMessage({
    required this.msgId,
    required this.msgType,
    required this.msgAuthor,
    this.msgText,
    this.msgImagesFilesUrls,
    this.msgDataType,
    required this.msgCreatedAt,
    required this.msgStatus,
    required this.requestId,
    this.userRating,
    this.userPhoto,
    this.userNumberOfRequestsOrDeliveries,
    this.currentLocation,
  });

  factory ModelMessage.fromJson(Map<String, dynamic> json) {
    return ModelMessage(
      msgId: json['msgId'] ?? '',
      msgType: json['msgType'] ?? '',
      msgDataType: json['msgDataType'] ?? '',
      msgAuthor: json['msgAuthor'] ?? '',
      msgText: json['msgText'] as String?,
      msgImagesFilesUrls: (json['msgImagesFilesUrls'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      msgCreatedAt: json['msgCreatedAt'] ?? '',
      msgStatus: json['msgStatus'] ?? '',
      requestId: json['requestId'] ?? '',
      // userRating: (json['userRating'] as num?)?.toDouble(), // New
      userRating: json['userRating'] ?? '', // New
      userPhoto: json['userPhoto'],                         // New
      currentLocation: json['currentLocation'],                         // New
      userNumberOfRequestsOrDeliveries: json['userNumberOfRequestsOrDeliveries'],                         // New
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'msgId': msgId,
      'msgType': msgType,
      'msgDataType': msgDataType,
      'msgAuthor': msgAuthor,
      'msgText': msgText,
      'msgImagesFilesUrls': msgImagesFilesUrls,
      'msgCreatedAt': msgCreatedAt,
      'msgStatus': msgStatus,
      'requestId': requestId,
      'userRating': userRating, // New
      'userPhoto': userPhoto,   // New
      'userNumberOfRequestsOrDeliveries': userNumberOfRequestsOrDeliveries,   // New
      'currentLocation': currentLocation,
    };
  }

  factory ModelMessage.fromMap(Map<String, dynamic> map) {
    return ModelMessage(
      msgId: map['msgId'] ?? '',
      msgType: map['msgType'] ?? '',
      msgDataType: map['msgDataType'] ?? '',
      msgAuthor: map['msgAuthor'] ?? '',
      msgText: map['msgText'] as String?,
      msgImagesFilesUrls: (map['msgImagesFilesUrls'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      msgCreatedAt: map['msgCreatedAt'] ?? '',
      currentLocation: map['currentLocation'] ?? '',
      msgStatus: map['msgStatus'] ?? '',
      requestId: map['requestId'] ?? '',
      userRating: map['userRating'], // Optional field, can be null
      userPhoto: map['userPhoto'], // Optional field, can be null
      userNumberOfRequestsOrDeliveries: map['userNumberOfRequestsOrDeliveries'], // Optional field, can be null
    );
  }
}
