import 'package:equatable/equatable.dart';

abstract class QRScanState extends Equatable {
  const QRScanState();

  @override
  List<Object?> get props => [];
}

class QRScanInitial extends QRScanState {}

class QRScanProcessing extends QRScanState {}

class QRScanSuccess extends QRScanState {
  final Map<String, dynamic> result;

  const QRScanSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class QRScanError extends QRScanState {
  final String message;

  const QRScanError(this.message);

  @override
  List<Object?> get props => [message];
}
