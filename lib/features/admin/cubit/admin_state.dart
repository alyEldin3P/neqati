import 'package:equatable/equatable.dart';
import 'package:neqati/features/admin/model/admin_stats.dart';
import 'package:neqati/features/auth/model/user.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminError extends AdminState {
  final String message;

  const AdminError(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminStatsLoaded extends AdminState {
  final AdminStats stats;

  const AdminStatsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

class UsersLoaded extends AdminState {
  final List<AppUser> users;
  final bool hasMore;

  const UsersLoaded(this.users, {this.hasMore = false});

  @override
  List<Object?> get props => [users, hasMore];
}

class PendingUsersLoaded extends AdminState {
  final List<AppUser> pendingUsers;

  const PendingUsersLoaded(this.pendingUsers);

  @override
  List<Object?> get props => [pendingUsers];
}

class UserActionSuccess extends AdminState {
  final String message;
  final String userId;
  final String action;

  const UserActionSuccess({
    required this.message,
    required this.userId,
    required this.action,
  });

  @override
  List<Object?> get props => [message, userId, action];
}

class QrCodesLoaded extends AdminState {
  final List<dynamic> qrCodes;
  final int totalQrCodes;

  const QrCodesLoaded(this.qrCodes, this.totalQrCodes);

  @override
  List<Object?> get props => [qrCodes, totalQrCodes];
}

class QrCodeCreated extends AdminState {
  final String qrCodeId;
  final String qrCodeData;

  const QrCodeCreated({
    required this.qrCodeId,
    required this.qrCodeData,
  });

  @override
  List<Object?> get props => [qrCodeId, qrCodeData];
}

class QrCodeDeleted extends AdminState {
  final String qrCodeId;

  const QrCodeDeleted({required this.qrCodeId});

  @override
  List<Object?> get props => [qrCodeId];
}

class GiftsLoaded extends AdminState {
  final List<dynamic> gifts;

  const GiftsLoaded(this.gifts);

  @override
  List<Object?> get props => [gifts];
}

class GiftActionSuccess extends AdminState {
  final String message;
  final String giftId;
  final String action;

  const GiftActionSuccess({
    required this.message,
    required this.giftId,
    required this.action,
  });

  @override
  List<Object?> get props => [message, giftId, action];
}

class OffersLoaded extends AdminState {
  final List<dynamic> offers;

  const OffersLoaded(this.offers);

  @override
  List<Object?> get props => [offers];
}

class OfferActionSuccess extends AdminState {
  final String message;
  final String offerId;
  final String action;

  const OfferActionSuccess({
    required this.message,
    required this.offerId,
    required this.action,
  });

  @override
  List<Object?> get props => [message, offerId, action];
}

class LevelsLoaded extends AdminState {
  final List<dynamic> levels;

  const LevelsLoaded(this.levels);

  @override
  List<Object?> get props => [levels];
}

class LevelActionSuccess extends AdminState {
  final String message;
  final String levelId;
  final String action;

  const LevelActionSuccess({
    required this.message,
    required this.levelId,
    required this.action,
  });

  @override
  List<Object?> get props => [message, levelId, action];
}

class ScansLoaded extends AdminState {
  final List<dynamic> scans;
  final bool hasMore;

  const ScansLoaded(this.scans, {this.hasMore = false});

  @override
  List<Object?> get props => [scans, hasMore];
}
