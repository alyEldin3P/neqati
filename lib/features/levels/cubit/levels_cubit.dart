import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/services/dependency_injector.dart';
import 'package:neqati/core/services/firestore_service.dart';
import 'package:neqati/features/auth/cubit/auth_cubit.dart';
import 'package:neqati/features/levels/cubit/levels_state.dart';
import 'package:neqati/features/levels/model/level.dart';

class LevelsCubit extends Cubit<LevelsState> {
  final FirestoreService _firestoreService;
  final AuthCubit _authCubit;

  LevelsCubit({
    FirestoreService? firestoreService,
    required AuthCubit authCubit,
  })  : _firestoreService = firestoreService ?? DependencyInjector.resolve<FirestoreService>(),
        _authCubit = authCubit,
        super(LevelsInitial());

  Future<void> loadLevels() async {
    emit(LevelsLoading());
    try {
      final levelsData = await _firestoreService.getLevels();
      
      final levels = levelsData.map((data) => Level.fromFirestore(data, data['id'] as String)).toList();
      
      // Sort levels by starting points
      levels.sort((a, b) => a.startingPoints.compareTo(b.startingPoints));
      
      // Get user data
      final authState = _authCubit.state;
      if (authState is AuthAuthenticated) {
        final userData = authState.userData;
        final userPoints = userData['points'] as int? ?? 0;
        final userLevelName = userData['level'] as String? ?? 'مبتدئ';
        
        // Find current user level
        final userCurrentLevel = levels.firstWhere(
          (level) => level.name == userLevelName,
          orElse: () => levels.first,
        );
        
        // Find next level
        Level? nextLevel;
        int pointsToNextLevel = 0;
        
        for (int i = 0; i < levels.length; i++) {
          if (levels[i].name == userCurrentLevel.name && i < levels.length - 1) {
            nextLevel = levels[i + 1];
            pointsToNextLevel = nextLevel.startingPoints - userPoints;
            break;
          }
        }
        
        emit(LevelsLoaded(
          levels: levels,
          userCurrentLevel: userCurrentLevel,
          nextLevel: nextLevel,
          userPoints: userPoints,
          pointsToNextLevel: pointsToNextLevel > 0 ? pointsToNextLevel : 0,
        ));
      } else {
        emit(LevelsLoaded(levels: levels));
      }
    } catch (e) {
      emit(LevelsError('حدث خطأ أثناء تحميل المستويات. يرجى المحاولة مرة أخرى.'));
    }
  }
}
