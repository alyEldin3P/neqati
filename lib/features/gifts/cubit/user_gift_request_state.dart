import 'package:equatable/equatable.dart';
import '../../admin/gift_management/model/gift_request.dart';

abstract class UserGiftRequestState extends Equatable {
  const UserGiftRequestState();

  @override
  List<Object?> get props => [];
}

class UserGiftRequestInitial extends UserGiftRequestState {}

class UserGiftRequestLoading extends UserGiftRequestState {}

class UserGiftRequestLoaded extends UserGiftRequestState {
  final List<GiftRequest> giftRequests;

  const UserGiftRequestLoaded({
    required this.giftRequests,
  });

  @override
  List<Object?> get props => [giftRequests];

  UserGiftRequestLoaded copyWith({
    List<GiftRequest>? giftRequests,
  }) {
    return UserGiftRequestLoaded(
      giftRequests: giftRequests ?? this.giftRequests,
    );
  }
}

class UserGiftRequestError extends UserGiftRequestState {
  final String message;

  const UserGiftRequestError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserGiftRequestDeleteLoading extends UserGiftRequestState {
  final String requestId;

  const UserGiftRequestDeleteLoading(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class UserGiftRequestDeleteSuccess extends UserGiftRequestState {
  final String message;
  final List<GiftRequest> updatedGiftRequests;

  const UserGiftRequestDeleteSuccess({
    required this.message,
    required this.updatedGiftRequests,
  });

  @override
  List<Object?> get props => [message, updatedGiftRequests];
}

class UserGiftRequestDeleteError extends UserGiftRequestState {
  final String message;

  const UserGiftRequestDeleteError(this.message);

  @override
  List<Object?> get props => [message];
}
