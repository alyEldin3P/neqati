import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/services/auth_service.dart';
import 'package:neqati/core/services/user_service.dart';
import 'package:neqati/features/admin/user_management/cubit/user_management_state.dart';
import 'package:neqati/features/auth/model/user.dart';

class UserManagementCubit extends Cubit<UserManagementState> {
  final UserService _userService;

  UserManagementCubit({required UserService userService})
    : _userService = userService,
      super(UserManagementInitial());

  // User Management
  Future<void> loadUsers({int limit = 20, int offset = 0}) async {
    try {
      emit(UserManagementLoading());

      final usersData = await _userService.getUsersPaginated(
        limit: limit,
        offset: offset,
      );

      final users =
          usersData.map((data) {
            return AppUser.fromSupabase(data, data['id']);
          }).toList();

      final hasMore = usersData.length == limit;

      emit(UsersLoaded(users, hasMore: hasMore));
    } catch (e) {
      emit(UserManagementError('Failed to load users: ${e.toString()}'));
    }
  }

  Future<void> loadPendingUsers() async {
    try {
      emit(UserManagementLoading());

      final pendingUsersData = await _userService.getPendingUsers();

      final pendingUsers =
          pendingUsersData.map((data) {
            return AppUser.fromSupabase(data, data['id']);
          }).toList();

      emit(PendingUsersLoaded(pendingUsers));
    } catch (e) {
      emit(
        UserManagementError('Failed to load pending users: ${e.toString()}'),
      );
    }
  }

  Future<void> verifyUser(String userId) async {
    try {
      emit(UserManagementLoading());

      await _userService.verifyUser(userId);

      emit(
        UserActionSuccess(
          message: 'تم تفعيل المستخدم بنجاح',
          userId: userId,
          action: 'verify',
        ),
      );
    } catch (e) {
      emit(UserManagementError('Failed to verify user: ${e.toString()}'));
    }
  }

  Future<void> blockUser(String userId, bool isBlocked) async {
    try {
      emit(UserManagementLoading());

      await _userService.blockUser(userId, isBlocked);

      final message =
          isBlocked ? 'تم حظر المستخدم بنجاح' : 'تم إلغاء حظر المستخدم بنجاح';

      emit(
        UserActionSuccess(
          message: message,
          userId: userId,
          action: isBlocked ? 'block' : 'unblock',
        ),
      );
    } catch (e) {
      emit(
        UserManagementError(
          'Failed to update user block status: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> toggleAdminStatus(String userId, bool isAdmin) async {
    try {
      emit(UserManagementLoading());

      await _userService.toggleAdminStatus(userId, isAdmin);

      final message =
          isAdmin ? 'تمت الترقية إلى مدير بنجاح' : 'تم إلغاء صلاحيات المدير بنجاح';

      emit(
        UserActionSuccess(
          message: message,
          userId: userId,
          action: isAdmin ? 'make_admin' : 'remove_admin',
        ),
      );
    } catch (e) {
      emit(
        UserManagementError(
          'Failed to update user admin status: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> updateUserPoints(String userId, int points) async {
    try {
      emit(UserManagementLoading());

      await _userService.updateUserPointsAdmin(userId, points);

      emit(
        UserActionSuccess(
          message: 'تم تحديث نقاط المستخدم بنجاح',
          userId: userId,
          action: 'update_points',
        ),
      );
    } catch (e) {
      emit(
        UserManagementError('Failed to update user points: ${e.toString()}'),
      );
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      emit(UserManagementLoading());

      await _userService.deleteUser(userId);

      emit(
        UserActionSuccess(
          message: 'تم حذف المستخدم بنجاح',
          userId: userId,
          action: 'delete',
        ),
      );
    } catch (e) {
      emit(UserManagementError('Failed to delete user: ${e.toString()}'));
    }
  }

  Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      print(
        'UserManagementCubit: Starting createUser with userData: $userData',
      );
      emit(UserManagementLoading());

      print('UserManagementCubit: Calling SupabaseService.createUser...');
      final userId = await _userService.createUser(userData);
      print(
        'UserManagementCubit: SupabaseService.createUser completed with userId: $userId',
      );

      emit(
        UserActionSuccess(
          message: 'تم إنشاء المستخدم بنجاح',
          userId: userId,
          action: 'create',
        ),
      );
      print('UserManagementCubit: Emitted UserActionSuccess');
    } catch (e) {
      print('UserManagementCubit: createUser failed with error: $e');
      print('UserManagementCubit: Error type: ${e.runtimeType}');
      print('UserManagementCubit: Stack trace: ${StackTrace.current}');
      emit(UserManagementError('Failed to create user: ${e.toString()}'));
    }
  }
}
