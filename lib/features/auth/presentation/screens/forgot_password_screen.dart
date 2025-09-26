import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/widgets/app_button.dart';
import '../../../../core/presentation/widgets/app_form_field.dart';
import '../../../../core/presentation/widgets/app_text.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dimensions.dart';
import '../../../../core/utils/app_validators.dart';
import '../../cubit/auth_cubit.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _resetPassword() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().resetPassword(_emailController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.deepTeal),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText.title(
          'استعادة كلمة المرور',
          color: AppColors.deepTeal,
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is AuthPasswordResetSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إرسال رابط استعادة كلمة المرور إلى بريدك الإلكتروني'),
                duration: Duration(seconds: 5),
              ),
            );
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppDimensions.large),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: AppDimensions.extraLarge),
                    
                    // Instructions
                    Container(
                      padding: EdgeInsets.all(AppDimensions.medium),
                      decoration: BoxDecoration(
                        color: AppColors.lightTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
                        border: Border.all(color: AppColors.lightTeal.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.deepTeal,
                            size: 32,
                          ),
                          SizedBox(height: AppDimensions.small),
                          AppText(
                            'أدخل بريدك الإلكتروني وسنرسل لك رابط استعادة كلمة المرور',
                            textAlign: TextAlign.center,
                            color: AppColors.deepTeal,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppDimensions.extraLarge),

                    // Email Field
                    AppFormField(
                      controller: _emailController,
                      label: 'البريد الإلكتروني',
                      hint: 'example@domain.com',
                      prefix: const Icon(Icons.email),
                      keyboardType: TextInputType.emailAddress,
                      validator: AppValidators.validateEmail,
                    ),
                    SizedBox(height: AppDimensions.large),

                    // Reset Button
                    state is AuthLoading
                        ? const Center(child: AppLoadingIndicator())
                        : AppButton(
                            text: 'إرسال رابط الاستعادة',
                            onPressed: _resetPassword,
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
