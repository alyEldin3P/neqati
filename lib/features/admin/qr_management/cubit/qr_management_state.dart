import 'package:equatable/equatable.dart';

abstract class QrManagementState extends Equatable {
  const QrManagementState();

  @override
  List<Object> get props => [];
}

class QrManagementInitial extends QrManagementState {}

class QrManagementLoading extends QrManagementState {}

class QrCodesLoaded extends QrManagementState {
  final List<Map<String, dynamic>> qrCodes;
  final int totalQrCodes;

  const QrCodesLoaded(this.qrCodes, this.totalQrCodes);

  @override
  List<Object> get props => [qrCodes, totalQrCodes];
}

class QrCodeCreated extends QrManagementState {
  final String qrCodeId;
  final String qrCodeData;

  const QrCodeCreated({
    required this.qrCodeId,
    required this.qrCodeData,
  });

  @override
  List<Object> get props => [qrCodeId, qrCodeData];
}

class QrCodeDeleted extends QrManagementState {
  final String qrCodeId;

  const QrCodeDeleted({required this.qrCodeId});

  @override
  List<Object> get props => [qrCodeId];
}

class QrManagementError extends QrManagementState {
  final String message;

  const QrManagementError(this.message);

  @override
  List<Object> get props => [message];
}
