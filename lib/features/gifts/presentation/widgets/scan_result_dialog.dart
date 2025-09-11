import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/widgets/app_text.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dimensions.dart';
import '../../../auth/cubit/auth_cubit.dart';

class ScanResultDialog extends StatelessWidget {
  final Map<String, dynamic> result;

  const ScanResultDialog({
    Key? key,
    required this.result,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isSuccess = result['success'] ?? false;
    final int pointsEarned = result['pointsEarned'] ?? 0;
    final String message = result['message'] ?? '';
    final String locationName = result['locationName'] ?? 'غير معروف';
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isSuccess ? AppColors.lightTeal : AppColors.alertRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? AppColors.deepTeal : AppColors.alertRed,
                size: 50,
              ),
            ),
            SizedBox(height: AppDimensions.medium),
            
            // Title
            AppText.title(
              isSuccess ? 'تم المسح بنجاح!' : 'فشل المسح',
              color: isSuccess ? AppColors.deepTeal : AppColors.alertRed,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimensions.small),
            
            // Location
            if (isSuccess) ...[
              AppText(
                'الموقع: $locationName',
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimensions.small),
            ],
            
            // Points earned
            if (isSuccess && pointsEarned > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: AppColors.goldAccent),
                  SizedBox(width: AppDimensions.tiny),
                  AppText(
                    'تم إضافة $pointsEarned نقطة',
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
              SizedBox(height: AppDimensions.small),
              
              // Update total points
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  if (state is AuthAuthenticated) {
                    final int totalPoints = state.userData['points'] as int? ?? 0;
                    return AppText(
                      'رصيدك الحالي: $totalPoints نقطة',
                      color: AppColors.deepTeal,
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
            
            // Message
            if (message.isNotEmpty) ...[
              SizedBox(height: AppDimensions.small),
              AppText(
                message,
                textAlign: TextAlign.center,
              ),
            ],
            
            SizedBox(height: AppDimensions.large),
            
            // Button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSuccess ? AppColors.deepTeal : AppColors.alertRed,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                ),
              ),
              child: AppText(
                'حسناً',
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
