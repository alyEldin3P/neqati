import 'package:equatable/equatable.dart';

abstract class GiftState extends Equatable {
  const GiftState();

  @override
  List<Object?> get props => [];
}

class GiftInitial extends GiftState {}

class GiftLoading extends GiftState {}

class GiftLoaded extends GiftState {
  final List<Map<String, dynamic>> gifts;
  final int userPoints;

  const GiftLoaded({
    required this.gifts,
    required this.userPoints,
  });

  @override
  List<Object?> get props => [gifts, userPoints];

  GiftLoaded copyWith({
    List<Map<String, dynamic>>? gifts,
    int? userPoints,
  }) {
    return GiftLoaded(
      gifts: gifts ?? this.gifts,
      userPoints: userPoints ?? this.userPoints,
    );
  }
}

class GiftError extends GiftState {
  final String message;

  const GiftError(this.message);

  @override
  List<Object?> get props => [message];
}

class GiftRequestLoading extends GiftState {}

class GiftRequestSuccess extends GiftState {
  final String message;
  final int newUserPoints;
  final List<Map<String, dynamic>> gifts;

  const GiftRequestSuccess({
    required this.message,
    required this.newUserPoints,
    required this.gifts,
  });

  @override
  List<Object?> get props => [message, newUserPoints, gifts];
}

class GiftRequestError extends GiftState {
  final String message;

  const GiftRequestError(this.message);

  @override
  List<Object?> get props => [message];
}