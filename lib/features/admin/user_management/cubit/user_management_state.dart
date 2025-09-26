import 'package:equatable/equatable.dart';
import 'package:neqati/features/auth/model/user.dart';

abstract class UserManagementState extends Equatable {
  const UserManagementState();

  @override
  List<Object> get props => [];
}

class UserManagementInitial extends UserManagementState {}

class UserManagementLoading extends UserManagementState {}

class UsersLoaded extends UserManagementState {
  final List<AppUser> users;
  final bool hasMore;

  const UsersLoaded(this.users, {this.hasMore = false});

  @override
  List<Object> get props => [users, hasMore];
}

class PendingUsersLoaded extends UserManagementState {
  final List<AppUser> pendingUsers;

  const PendingUsersLoaded(this.pendingUsers);

  @override
  List<Object> get props => [pendingUsers];
}

class UserActionSuccess extends UserManagementState {
  final String message;
  final String userId;
  final String action;

  const UserActionSuccess({
    required this.message,
    required this.userId,
    required this.action,
  });

  @override
  List<Object> get props => [message, userId, action];
}

class UserManagementError extends UserManagementState {
  final String message;

  const UserManagementError(this.message);

  @override
  List<Object> get props => [message];
}
