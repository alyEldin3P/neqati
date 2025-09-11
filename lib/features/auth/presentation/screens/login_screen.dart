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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _phoneController.dispose();
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
      context.read<AuthCubit>().signInWithPhoneAndPassword(_phoneController.text, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is AuthNotVerified) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('حسابك قيد المراجعة من قبل الإدارة. يرجى المحاولة لاحقاً.')));
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
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 120,
                          // If logo asset doesn't exist yet, use a placeholder
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                height: 120,
                                width: 120,
                                decoration: BoxDecoration(color: AppColors.deepTeal, shape: BoxShape.circle),
                                child: const Center(
                                  child: Text(
                                    'نقاطي',
                                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                        ),
                      ),
                      SizedBox(height: AppDimensions.large),

                      // Title
                      AppText.title('تسجيل الدخول', textAlign: TextAlign.center, color: AppColors.deepTeal),
                      SizedBox(height: AppDimensions.extraLarge),

                      // Phone Field
                      AppFormField(
                        controller: _phoneController,
                        label: 'رقم الهاتف',
                        hint: '05xxxxxxxx',
                        prefix: const Icon(Icons.phone),
                        keyboardType: TextInputType.phone,
                        validator: AppValidators.validatePhoneNumber,
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
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppText('ليس لديك حساب؟', color: AppColors.textSecondary),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                            },
                            child: AppText('تسجيل جديد', color: AppColors.deepTeal, fontWeight: FontWeight.bold),
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
