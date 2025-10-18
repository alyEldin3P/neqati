import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/services/level_service.dart';
import 'package:neqati/core/services/user_service.dart';
import 'package:neqati/features/admin/level_management/cubit/level_management_state.dart';

class LevelManagementCubit extends Cubit<LevelManagementState> {
  final LevelService _levelService;
  final UserService _userService;

  LevelManagementCubit({
    required LevelService levelService,
    required UserService userService,
  })  : _levelService = levelService,
        _userService = userService,
        super(LevelManagementInitial());

  // Level Management
  Future<void> loadLevels() async {
    try {
      emit(LevelManagementLoading());

      final levels = await _levelService.getLevels();

      emit(LevelsLoaded(levels));
    } catch (e) {
      emit(LevelManagementError('Failed to load levels: ${e.toString()}'));
    }
  }

  Future<void> createLevel(Map<String, dynamic> levelData) async {
    try {
      emit(LevelManagementLoading());

      final levelId = await _levelService.createLevel(levelData);

      emit(
        LevelActionSuccess(
          message: 'تم إنشاء المستوى بنجاح',
          levelId: levelId,
          action: 'create',
        ),
      );
    } catch (e) {
      emit(LevelManagementError('Failed to create level: ${e.toString()}'));
    }
  }

  Future<Map<String, dynamic>?> getLevelById(String levelId) async {
    try {
      return await _levelService.getLevelById(levelId);
    } catch (e) {
      emit(LevelManagementError('Failed to get level: ${e.toString()}'));
      return null;
    }
  }

  Future<void> updateLevel({
    required String levelId,
    required Map<String, dynamic> levelData,
  }) async {
    try {
      emit(LevelManagementLoading());

      await _levelService.updateLevel(
        levelId: levelId,
        levelData: levelData,
      );

      emit(
        LevelActionSuccess(
          message: 'تم تحديث المستوى بنجاح',
          levelId: levelId,
          action: 'update',
        ),
      );
    } catch (e) {
      emit(LevelManagementError('Failed to update level: ${e.toString()}'));
    }
  }

  Future<void> deleteLevel(String levelId) async {
    try {
      emit(LevelManagementLoading());

      await _levelService.deleteLevel(levelId);

      emit(
        LevelActionSuccess(
          message: 'تم حذف المستوى بنجاح',
          levelId: levelId,
          action: 'delete',
        ),
      );
    } catch (e) {
      emit(LevelManagementError('Failed to delete level: ${e.toString()}'));
    }
  }

  // Bulk reset all users to a specific level
  Future<void> resetAllUsersToLevel(String levelName) async {
    try {
      emit(LevelManagementLoading());

      final count = await _userService.resetAllUsersToLevel(levelName);

      emit(
        LevelActionSuccess(
          message: 'تم إعادة تعيين $count مستخدم إلى مستوى $levelName بنجاح',
          levelId: '',
          action: 'bulk_reset',
        ),
      );
    } catch (e) {
      emit(
        LevelManagementError('فشل إعادة تعيين المستويات: ${e.toString()}'),
      );
    }
  }
}
