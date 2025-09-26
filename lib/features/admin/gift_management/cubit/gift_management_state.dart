import 'package:equatable/equatable.dart';

abstract class GiftManagementState extends Equatable {
  const GiftManagementState();

  @override
  List<Object> get props => [];
}

class GiftManagementInitial extends GiftManagementState {}

class GiftManagementLoading extends GiftManagementState {}

class GiftsLoaded extends GiftManagementState {
  final List<Map<String, dynamic>> gifts;

  const GiftsLoaded(this.gifts);

  @override
  List<Object> get props => [gifts];
}

class GiftActionSuccess extends GiftManagementState {
  final String message;
  final String giftId;
  final String action;

  const GiftActionSuccess({
    required this.message,
    required this.giftId,
    required this.action,
  });

  @override
  List<Object> get props => [message, giftId, action];
}

class GiftManagementError extends GiftManagementState {
  final String message;

  const GiftManagementError(this.message);

  @override
  List<Object> get props => [message];
}
