import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_loading_indicator.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/core/utils/app_colors.dart';
import 'package:neqati/core/utils/app_dimensions.dart';
import 'package:neqati/features/levels/cubit/levels_cubit.dart';
import 'package:neqati/features/levels/cubit/levels_state.dart';
import 'package:neqati/features/levels/model/level.dart';

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({Key? key}) : super(key: key);

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LevelsCubit>().loadLevels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.title('المستويات', color: Colors.white),
        backgroundColor: AppColors.deepTeal,
        centerTitle: true,
      ),
      body: BlocBuilder<LevelsCubit, LevelsState>(
        builder: (context, state) {
          if (state is LevelsLoading) {
            return const Center(child: AppLoadingIndicator());
          } else if (state is LevelsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(state.message, color: AppColors.alertRed),
                  SizedBox(height: AppDimensions.medium),
                  ElevatedButton(
                    onPressed: () => context.read<LevelsCubit>().loadLevels(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepTeal,
                    ),
                    child: const AppText('إعادة المحاولة', color: Colors.white),
                  ),
                ],
              ),
            );
          } else if (state is LevelsLoaded) {
            return _buildLevelsContent(state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLevelsContent(LevelsLoaded state) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.userCurrentLevel != null) ...[
            _buildUserLevelInfo(state),
            SizedBox(height: AppDimensions.large),
          ],
          AppText.subtitle(
            'جميع المستويات',
            color: AppColors.deepTeal,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: AppDimensions.medium),
          ...state.levels.map((level) => _buildLevelCard(
                level,
                isUserLevel: state.userCurrentLevel?.id == level.id,
                isNextLevel: state.nextLevel?.id == level.id,
              )),
        ],
      ),
    );
  }

  Widget _buildUserLevelInfo(LevelsLoaded state) {
    final currentLevel = state.userCurrentLevel!;
    final nextLevel = state.nextLevel;
    
    return AppContainer(
      backgroundColor: AppColors.deepTeal,
      padding: EdgeInsets.all(AppDimensions.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.white.withOpacity(0.2),
                child: currentLevel.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.network(
                          currentLevel.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.emoji_events,
                              color: AppColors.goldAccent,
                              size: 30,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.emoji_events,
                        color: AppColors.goldAccent,
                        size: 30,
                      ),
              ),
              SizedBox(width: AppDimensions.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'المستوى الحالي',
                      color: AppColors.white.withOpacity(0.8),
                    ),
                    AppText.title(
                      currentLevel.name,
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.medium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'نقاطك الحالية',
                    color: AppColors.white.withOpacity(0.8),
                    isSmall: true,
                  ),
                  Row(
                    children: [
                      Icon(Icons.star, color: AppColors.goldAccent, size: 20),
                      SizedBox(width: AppDimensions.tiny),
                      AppText.subtitle(
                        '${state.userPoints}',
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'معامل المضاعفة',
                    color: AppColors.white.withOpacity(0.8),
                    isSmall: true,
                  ),
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: AppColors.goldAccent, size: 20),
                      SizedBox(width: AppDimensions.tiny),
                      AppText.subtitle(
                        '${currentLevel.multiplier}x',
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (nextLevel != null) ...[
            SizedBox(height: AppDimensions.medium),
            Divider(color: AppColors.white.withOpacity(0.2)),
            SizedBox(height: AppDimensions.small),
            AppText(
              'المستوى التالي: ${nextLevel.name}',
              color: AppColors.white,
            ),
            SizedBox(height: AppDimensions.small),
            LinearProgressIndicator(
              value: _calculateLevelProgress(state),
              backgroundColor: AppColors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.goldAccent),
            ),
            SizedBox(height: AppDimensions.tiny),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  '${state.userPoints} نقطة',
                  color: AppColors.white.withOpacity(0.8),
                  isSmall: true,
                ),
                AppText(
                  '${nextLevel.startingPoints} نقطة',
                  color: AppColors.white.withOpacity(0.8),
                  isSmall: true,
                ),
              ],
            ),
            SizedBox(height: AppDimensions.small),
            Center(
              child: AppText(
                'تحتاج ${state.pointsToNextLevel} نقطة للوصول للمستوى التالي',
                color: AppColors.goldAccent,
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _calculateLevelProgress(LevelsLoaded state) {
    if (state.nextLevel == null || state.userCurrentLevel == null) return 0.0;
    
    final currentLevelPoints = state.userCurrentLevel!.startingPoints;
    final nextLevelPoints = state.nextLevel!.startingPoints;
    final userPoints = state.userPoints;
    
    final totalPointsNeeded = nextLevelPoints - currentLevelPoints;
    final userProgress = userPoints - currentLevelPoints;
    
    if (totalPointsNeeded <= 0) return 1.0;
    return userProgress / totalPointsNeeded;
  }

  Widget _buildLevelCard(Level level, {bool isUserLevel = false, bool isNextLevel = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppDimensions.medium),
      child: AppContainer(
        padding: EdgeInsets.all(AppDimensions.medium),
        border: isUserLevel
            ? Border.all(color: AppColors.goldAccent, width: 2)
            : isNextLevel
                ? Border.all(color: AppColors.deepTeal, width: 2)
                : null,
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.lightTeal,
              child: level.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.network(
                        level.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.emoji_events,
                            color: isUserLevel ? AppColors.goldAccent : AppColors.deepTeal,
                            size: 25,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.emoji_events,
                      color: isUserLevel ? AppColors.goldAccent : AppColors.deepTeal,
                      size: 25,
                    ),
            ),
            SizedBox(width: AppDimensions.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppText.subtitle(
                        level.name,
                        fontWeight: FontWeight.bold,
                        color: isUserLevel ? AppColors.goldAccent : AppColors.deepTeal,
                      ),
                      if (isUserLevel)
                        Padding(
                          padding: EdgeInsets.only(right: AppDimensions.small),
                          child: Icon(
                            Icons.check_circle,
                            color: AppColors.goldAccent,
                            size: 16,
                          ),
                        ),
                      if (isNextLevel)
                        Padding(
                          padding: EdgeInsets.only(right: AppDimensions.small),
                          child: Icon(
                            Icons.arrow_circle_up,
                            color: AppColors.deepTeal,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: AppDimensions.tiny),
                  AppText(
                    'يبدأ من ${level.startingPoints} نقطة',
                    isSmall: true,
                  ),
                  SizedBox(height: AppDimensions.tiny),
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: AppColors.deepTeal,
                        size: 14,
                      ),
                      SizedBox(width: AppDimensions.tiny),
                      AppText(
                        'معامل المضاعفة: ${level.multiplier}x',
                        isSmall: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
