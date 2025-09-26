import 'package:equatable/equatable.dart';

abstract class ScanHistoryState extends Equatable {
  const ScanHistoryState();

  @override
  List<Object> get props => [];
}

class ScanHistoryInitial extends ScanHistoryState {}

class ScanHistoryLoading extends ScanHistoryState {}

class ScansLoaded extends ScanHistoryState {
  final List<Map<String, dynamic>> scans;
  final bool hasMore;

  const ScansLoaded(this.scans, {this.hasMore = false});

  @override
  List<Object> get props => [scans, hasMore];
}

class ScanHistoryError extends ScanHistoryState {
  final String message;

  const ScanHistoryError(this.message);

  @override
  List<Object> get props => [message];
}
