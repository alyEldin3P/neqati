import 'package:neqati/features/admin/gift_management/model/gift_request.dart';

abstract class GiftRequestManagementState {}

class GiftRequestManagementInitial extends GiftRequestManagementState {}

class GiftRequestManagementLoading extends GiftRequestManagementState {}

class GiftRequestManagementLoaded extends GiftRequestManagementState {
  final List<GiftRequest> giftRequests;

  GiftRequestManagementLoaded(this.giftRequests);
}

class GiftRequestManagementError extends GiftRequestManagementState {
  final String message;

  GiftRequestManagementError(this.message);
}

class GiftRequestActionSuccess extends GiftRequestManagementState {
  final String message;
  final String requestId;
  final String action; // 'approved' or 'rejected'

  GiftRequestActionSuccess({
    required this.message,
    required this.requestId,
    required this.action,
  });
}

class UserGiftRequestsLoading extends GiftRequestManagementState {}

class UserGiftRequestsLoaded extends GiftRequestManagementState {
  final List<GiftRequest> giftRequests;
  final String userId;

  UserGiftRequestsLoaded({
    required this.giftRequests,
    required this.userId,
  });
}

class UserGiftRequestsError extends GiftRequestManagementState {
  final String message;
  final String userId;

  UserGiftRequestsError({
    required this.message,
    required this.userId,
  });
}
