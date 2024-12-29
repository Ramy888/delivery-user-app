// offer_bloc.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as dev;


import '../Models/model_message.dart';
import 'offer_event.dart';
import 'offer_state.dart';

class OfferBloc extends Bloc<OfferEvent, OfferState> {
  final String requestId;

  OfferBloc(this.requestId) : super(OfferInitial()) {
    on<LoadOffers>(_onLoadOffers);
    on<AcceptOffer>(_onAcceptOffer);
    on<RejectOffer>(_onRejectOffer);
  }

  Future<void> _onLoadOffers(LoadOffers event, Emitter<OfferState> emit) async {
    emit(OfferLoading());
    try {
      Stream<List<ModelMessage>> offersStream = FirebaseFirestore.instance
          .collection('requests')
          .doc(event.requestId)
          .collection('chat')
          .orderBy('msgCreatedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ModelMessage.fromMap(doc.data()))
              .toList());

      await emit.forEach(offersStream,
          onData: (List<ModelMessage> offers) => OffersLoaded(offers));
    } catch (e) {
      emit(OfferError(e.toString()));
    }
  }

  Future<void> _onAcceptOffer(
      AcceptOffer event, Emitter<OfferState> emit) async {
    try {
      // Implement your accept offer logic here
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(event.reqId)
          .collection('chat')
          .doc(event.offer.msgId)
          .update({'msgStatus': 'accepted'});

      WriteBatch batch = FirebaseFirestore.instance.batch();

      DocumentReference requestRef = FirebaseFirestore.instance.collection('requests').doc(event.reqId);
      batch.update(requestRef, {
        'reqVat': event.reqVat ?? '0.0',
        'reqAcceptedDeliveryFees': event.reqAcceptedDeliveryFees ?? '0.0',
        'reqAppProfit': event.reqAppProfit ?? '0.0',
        'reqStatus' : 'ongoing'
      });

      // Query to find all other messages with msgType = 'offer' and msgStatus not 'rejected'
      QuerySnapshot offerMessagesSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .doc(event.reqId)
          .collection('chat')
          .where('msgType', isEqualTo: 'offer')
          .where('msgStatus', isNotEqualTo: 'rejected')
          .get();

      // Iterate through the documents and update their msgStatus to 'rejected'
      for (QueryDocumentSnapshot doc in offerMessagesSnapshot.docs) {
        if (doc.id != event.offer.msgId) { // Exclude the accepted message
          batch.update(doc.reference, {'msgStatus': 'rejected'});
        }
      }

      emit(OffersLoaded([], acceptedOffer: event.offer));
    } catch (e) {
      emit(OfferError(e.toString()));
    }
  }

  Future<void> _onRejectOffer(
      RejectOffer event, Emitter<OfferState> emit) async {
    try {
      // Implement your reject offer logic here
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(event.reqId)
          .collection('chat')
          .doc(event.offer.msgId)
          .update({'msgStatus': 'rejected'});
    } catch (e) {
      emit(OfferError(e.toString()));
    }
  }
}
