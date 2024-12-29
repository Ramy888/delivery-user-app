//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import '../API/firestore_operations.dart';
//
// class ChatProvider with ChangeNotifier {
//   final FirestoreApi _firestoreApi = FirestoreApi();
//   List<types.Message> _messages = [];
//
//   List<types.Message> get messages => _messages;
//
//   void fetchMessages(String requestId) {
//     _firestoreApi.getChatMessages(requestId).listen((snapshot) {
//       _messages = snapshot.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//
//         // Safely handle null or invalid timestamp values
//         final timestamp = data['timestamp'] is Timestamp
//             ? (data['timestamp'] as Timestamp).millisecondsSinceEpoch
//             : DateTime
//             .now()
//             .millisecondsSinceEpoch; // Use current time if timestamp is null
//
//         return types.TextMessage(
//           id: doc.id,
//           author: types.User(
//             id: data['senderId'] ?? 'unknown',
//             // Provide a fallback for senderId
//             firstName: data['senderType'] ??
//                 'unknown', // Provide a fallback for senderType
//           ),
//           createdAt: timestamp,
//           text: data['message'] ?? '', // Provide a fallback for message
//         );
//       }).toList();
//       notifyListeners();
//     });
//   }
//
//
//   Future<void> sendMessage(String requestId, String senderId, String senderType,
//       String text) async {
//     await _firestoreApi.addChatMessage(
//       requestId: requestId,
//       senderId: senderId,
//       senderType: senderType,
//       message: text,
//     );
//   }
// }