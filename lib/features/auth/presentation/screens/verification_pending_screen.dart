import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/widgets/app_button.dart';
import '../../../../core/presentation/widgets/app_text.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dimensions.dart';
import '../../cubit/auth_cubit.dart';
import 'login_screen.dart';

class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              const Icon(
                Icons.hourglass_top,
                size: 100,
                color: AppColors.deepTeal,
              ),
              SizedBox(height: AppDimensions.large),
              
              // Title
              AppText.title(
                'حسابك قيد المراجعة',
                textAlign: TextAlign.center,
                color: AppColors.deepTeal,
              ),
              SizedBox(height: AppDimensions.medium),
              
              // Description
              AppText(
                'حسابك قيد المراجعة من قبل الإدارة. سيتم إشعارك عند الموافقة على حسابك.',
                textAlign: TextAlign.center,
                color: AppColors.lightText,
              ),
              SizedBox(height: AppDimensions.extraLarge),
              
              // Return to Login Button
              AppButton(
                text: 'العودة لتسجيل الدخول',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider.value(
                        value: context.read<AuthCubit>(),
                        child: const LoginScreen(),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: AppDimensions.medium),
              
              // Contact Support
              TextButton(
                onPressed: () {
                  // Show contact information dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const AppText(
                        'معلومات التواصل',
                        textAlign: TextAlign.center,
                        fontWeight: FontWeight.bold,
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppText(
                            'للاستفسار عن حالة طلبك، يرجى التواصل معنا:',
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppDimensions.medium),
                          Row(
                            children: const [
                              Icon(Icons.phone, color: AppColors.deepTeal, size: 20),
                              SizedBox(width: 8),
                              AppText('0555555555'),
                            ],
                          ),
                          SizedBox(height: AppDimensions.small),
                          Row(
                            children: const [
                              Icon(Icons.email, color: AppColors.deepTeal, size: 20),
                              SizedBox(width: 8),
                              AppText('support@neqati.app'),
                            ],
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const AppText(
                            'إغلاق',
                            color: AppColors.deepTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: AppText(
                  'التواصل مع الدعم',
                  color: AppColors.deepTeal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
