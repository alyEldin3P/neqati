import 'package:equatable/equatable.dart';

abstract class OfferManagementState extends Equatable {
  const OfferManagementState();

  @override
  List<Object> get props => [];
}

class OfferManagementInitial extends OfferManagementState {}

class OfferManagementLoading extends OfferManagementState {}

class OffersLoaded extends OfferManagementState {
  final List<Map<String, dynamic>> offers;

  const OffersLoaded(this.offers);

  @override
  List<Object> get props => [offers];
}

class OfferActionSuccess extends OfferManagementState {
  final String message;
  final String offerId;
  final String action;

  const OfferActionSuccess({
    required this.message,
    required this.offerId,
    required this.action,
  });

  @override
  List<Object> get props => [message, offerId, action];
}

class OfferManagementError extends OfferManagementState {
  final String message;

  const OfferManagementError(this.message);

  @override
  List<Object> get props => [message];
}
