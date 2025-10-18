part of 'auth_cubit.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  final Map<String, dynamic> userData;
  final bool isAdmin;

  const AuthAuthenticated({
    required this.user,
    required this.userData,
    required this.isAdmin,
  });

  @override
  List<Object?> get props => [user, userData, isAdmin];
}

class AuthUnauthenticated extends AuthState {}

class AuthNotVerified extends AuthState {}

class AuthBlocked extends AuthState {}

class AuthRegistrationSuccess extends AuthState {}

class AuthPasswordResetSent extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
