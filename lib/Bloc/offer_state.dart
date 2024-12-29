// offer_state.dart
import '../Models/model_message.dart';

abstract class OfferState {
  const OfferState();
}

class OfferInitial extends OfferState {}

class OfferLoading extends OfferState {}

class OffersLoaded extends OfferState {
  final List<ModelMessage> offers;
  final ModelMessage? acceptedOffer;

  OffersLoaded(this.offers, {this.acceptedOffer});
}

class OfferError extends OfferState {
  final String message;
  OfferError(this.message);
}