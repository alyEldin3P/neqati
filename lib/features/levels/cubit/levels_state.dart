import 'package:equatable/equatable.dart';
import 'package:neqati/features/levels/model/level.dart';

abstract class LevelsState extends Equatable {
  const LevelsState();

  @override
  List<Object?> get props => [];
}

class LevelsInitial extends LevelsState {}

class LevelsLoading extends LevelsState {}

class LevelsLoaded extends LevelsState {
  final List<Level> levels;
  final Level? userCurrentLevel;
  final Level? nextLevel;
  final int userPoints;
  final int pointsToNextLevel;

  const LevelsLoaded({
    required this.levels,
    this.userCurrentLevel,
    this.nextLevel,
    this.userPoints = 0,
    this.pointsToNextLevel = 0,
  });

  @override
  List<Object?> get props => [levels, userCurrentLevel, nextLevel, userPoints, pointsToNextLevel];
}

class LevelsError extends LevelsState {
  final String message;

  const LevelsError(this.message);

  @override
  List<Object> get props => [message];
}
