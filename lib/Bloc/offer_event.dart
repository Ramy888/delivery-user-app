// offer_event.dart
import '../Models/model_message.dart';

abstract class OfferEvent {}

class LoadOffers extends OfferEvent {
  final String requestId;
  LoadOffers(this.requestId);
}

class AcceptOffer extends OfferEvent {
  final ModelMessage offer;
  final String reqVat;
  final String reqAcceptedDeliveryFees;
  final String reqAppProfit;
  final String reqId;
  AcceptOffer(this.offer, this.reqVat, this.reqAcceptedDeliveryFees, this.reqAppProfit, this.reqId);
}

class RejectOffer extends OfferEvent {
  final ModelMessage offer;
  final String reqId;
  RejectOffer(this.offer, this.reqId);
}