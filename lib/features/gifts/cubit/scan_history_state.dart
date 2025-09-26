import 'package:equatable/equatable.dart';

abstract class ScanHistoryState extends Equatable {
  const ScanHistoryState();

  @override
  List<Object?> get props => [];
}

class ScanHistoryInitial extends ScanHistoryState {}

class ScanHistoryLoading extends ScanHistoryState {}

class ScanHistoryLoaded extends ScanHistoryState {
  final List<Map<String, dynamic>> scanHistory;

  const ScanHistoryLoaded(this.scanHistory);

  @override
  List<Object?> get props => [scanHistory];
}

class ScanHistoryError extends ScanHistoryState {
  final String message;

  const ScanHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
