import 'dart:developer' as dev;
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
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      dev.log(
        'LoginScreen: Attempting login with email: ${_emailController.text}',
      );
      context.read<AuthCubit>().signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          dev.log('LoginScreen: Auth state changed to: ${state.runtimeType}');
          if (state is AuthAuthenticated) {
            dev.log(
              'LoginScreen: User authenticated, isAdmin: ${state.isAdmin}',
            );
            // We don't need to navigate here as it's handled by the BlocBuilder in main.dart
            // But let's add a log to confirm the state is correct
            dev.log(
              'LoginScreen: Navigation should happen automatically via main.dart BlocBuilder',
            );
          } else if (state is AuthError) {
            dev.log('LoginScreen: Authentication error: ${state.message}');
            // Show error snackbar with better styling
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.message,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.alertRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: EdgeInsets.all(16),
                duration: Duration(seconds: 4),
              ),
            );
          } else if (state is AuthNotVerified) {
            dev.log('LoginScreen: User not verified');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'حسابك قيد المراجعة من قبل الإدارة. يرجى المحاولة لاحقاً.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.warningOrange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: EdgeInsets.all(16),
                duration: Duration(seconds: 4),
              ),
            );
          } else if (state is AuthBlocked) {
            dev.log('LoginScreen: User is blocked');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.block, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تم حظر حسابك من قبل الإدارة. يرجى التواصل مع الدعم الفني.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.alertRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: EdgeInsets.all(16),
                duration: Duration(seconds: 5),
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppDimensions.large),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Center(
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage(
                                'assets/images/app_icon_trans.png',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppDimensions.large),

                      // Title
                      AppText.title(
                        'تسجيل الدخول',
                        textAlign: TextAlign.center,
                        color: AppColors.deepTeal,
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
                      SizedBox(height: AppDimensions.medium),

                      // Password Field
                      AppFormField(
                        controller: _passwordController,
                        label: 'كلمة المرور',
                        hint: '******',
                        prefix: const Icon(Icons.lock),
                        isPassword: true,
                        suffix: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.deepTeal,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                        validator: AppValidators.validatePassword,
                      ),
                      SizedBox(height: AppDimensions.medium),

                      // Login Button
                      state is AuthLoading
                          ? const Center(child: AppLoadingIndicator())
                          : AppButton(text: 'تسجيل الدخول', onPressed: _login),
                      SizedBox(height: AppDimensions.medium),

                      // Forgot Password Link
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: AppText(
                            'نسيت كلمة المرور؟',
                            color: AppColors.deepTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: AppDimensions.small),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppText(
                            'ليس لديك حساب؟',
                            color: AppColors.textSecondary,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: AppText(
                              'تسجيل جديد',
                              color: AppColors.deepTeal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
