import 'package:equatable/equatable.dart';
import 'package:neqati/features/admin/dashboard/model/admin_stats.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardStatsLoaded extends DashboardState {
  final AdminStats stats;

  const DashboardStatsLoaded(this.stats);

  @override
  List<Object> get props => [stats];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object> get props => [message];
}
