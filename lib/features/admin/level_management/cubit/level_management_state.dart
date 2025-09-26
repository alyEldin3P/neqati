import 'package:equatable/equatable.dart';

abstract class LevelManagementState extends Equatable {
  const LevelManagementState();

  @override
  List<Object> get props => [];
}

class LevelManagementInitial extends LevelManagementState {}

class LevelManagementLoading extends LevelManagementState {}

class LevelsLoaded extends LevelManagementState {
  final List<Map<String, dynamic>> levels;

  const LevelsLoaded(this.levels);

  @override
  List<Object> get props => [levels];
}

class LevelActionSuccess extends LevelManagementState {
  final String message;
  final String levelId;
  final String action;

  const LevelActionSuccess({
    required this.message,
    required this.levelId,
    required this.action,
  });

  @override
  List<Object> get props => [message, levelId, action];
}

class LevelManagementError extends LevelManagementState {
  final String message;

  const LevelManagementError(this.message);

  @override
  List<Object> get props => [message];
}
