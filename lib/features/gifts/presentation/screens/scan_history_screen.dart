import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/widgets/app_text.dart';
import '../../../../core/presentation/widgets/app_container.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dimensions.dart';
import '../../../auth/cubit/auth_cubit.dart';
import '../../cubit/scan_history_cubit.dart';
import '../../cubit/scan_history_state.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadScanHistory();
  }

  void _loadScanHistory() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<UserScanHistoryCubit>().loadScanHistory(authState.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.deepTeal,
        title: AppText('سجل المسح', color: AppColors.white, fontWeight: FontWeight.bold),
        centerTitle: true,
      ),
      body: BlocBuilder<UserScanHistoryCubit, ScanHistoryState>(
        builder: (context, state) {
          if (state is ScanHistoryLoading) {
            return const Center(child: AppLoadingIndicator());
          }

          if (state is ScanHistoryError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.large),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: AppColors.alertRed, size: 48),
                    SizedBox(height: AppDimensions.medium),
                    AppText(
                      state.message,
                      color: AppColors.alertRed,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppDimensions.large),
                    ElevatedButton(
                      onPressed: _loadScanHistory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepTeal,
                      ),
                      child: AppText('إعادة المحاولة', color: AppColors.white),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is ScanHistoryLoaded) {
            if (state.scanHistory.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.large),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, color: AppColors.lightTeal, size: 64),
                      SizedBox(height: AppDimensions.medium),
                      AppText(
                        'لا يوجد سجل مسح حتى الآن',
                        color: AppColors.deepTeal,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: AppDimensions.small),
                      AppText(
                        'قم بمسح رمز QR لكسب النقاط وستظهر هنا',
                        color: AppColors.lightText,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadScanHistory(),
              color: AppColors.deepTeal,
              child: ListView.builder(
                padding: EdgeInsets.all(AppDimensions.medium),
                itemCount: state.scanHistory.length,
                itemBuilder: (context, index) {
                  final scan = state.scanHistory[index];
                  final pointsEarned = scan['points_earned'] ?? 0;
                  final branch = scan['branch'] ?? 'غير معروف';
                  final scanDate = scan['scan_date'] != null ? DateTime.parse(scan['scan_date']) : DateTime.now();
                  
                  // Format date for display
                  final formattedDate = _formatDate(scanDate);
                  
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppDimensions.small),
                    child: AppContainer(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.lightTeal,
                          child: Icon(Icons.qr_code, color: AppColors.deepTeal),
                        ),
                        title: AppText('فرع $branch', fontWeight: FontWeight.bold),
                        subtitle: AppText('تم إضافة $pointsEarned نقطة', isSmall: true),
                        trailing: AppText(formattedDate, isCaption: true),
                      ),
                    ),
                  );
                },
              ),
            );
          }

          // Handle initial state
          final authState = context.read<AuthCubit>().state;
          if (authState is! AuthAuthenticated) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.large),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: AppColors.alertRed, size: 48),
                    SizedBox(height: AppDimensions.medium),
                    AppText(
                      'يجب تسجيل الدخول لعرض سجل المسح',
                      color: AppColors.alertRed,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return const Center(child: AppLoadingIndicator());
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
