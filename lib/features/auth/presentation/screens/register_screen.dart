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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedPosition = 'مقاول';
  final _positions = ['مقاول', 'مهندس', 'فني'];

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().registerUser(
        name: _nameController.text,
        address: _addressController.text,
        nationalId: _nationalIdController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        password: _passwordController.text,
        position: _selectedPosition,
      );
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
        title: AppText.title('تسجيل جديد', color: AppColors.deepTeal),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is AuthRegistrationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم التسجيل بنجاح. يرجى انتظار موافقة الإدارة.'),
                duration: Duration(seconds: 5),
              ),
            );
            final navigator = Navigator.of(context);
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                navigator.pop();
              }
            });
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
                    // Name Field
                    AppFormField(
                      controller: _nameController,
                      label: 'الاسم',
                      hint: 'أدخل الاسم الكامل',
                      prefix: const Icon(Icons.person),
                      validator:
                          (value) =>
                              AppValidators.validateEmptyField(value, 'الاسم'),
                    ),
                    SizedBox(height: AppDimensions.medium),

                    // Address Field
                    AppFormField(
                      controller: _addressController,
                      label: 'العنوان',
                      hint: 'أدخل العنوان',
                      prefix: const Icon(Icons.location_on),
                      validator:
                          (value) => AppValidators.validateEmptyField(
                            value,
                            'العنوان',
                          ),
                    ),
                    SizedBox(height: AppDimensions.medium),

                    // National ID Field
                    AppFormField(
                      controller: _nationalIdController,
                      label: 'رقم الهوية الوطنية',
                      hint: '14 رقم',
                      prefix: const Icon(Icons.badge),
                      keyboardType: TextInputType.number,
                      validator: AppValidators.validateNationalId,
                    ),
                    SizedBox(height: AppDimensions.medium),

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

                    // Position Dropdown
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.medium,
                        vertical: AppDimensions.small,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.buttonRadius,
                        ),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.work, color: AppColors.deepTeal),
                          SizedBox(width: AppDimensions.medium),
                          AppText('المنصب:', color: AppColors.lightText),
                          SizedBox(width: AppDimensions.medium),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedPosition,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: AppColors.deepTeal,
                                ),
                                items:
                                    _positions.map((String position) {
                                      return DropdownMenuItem<String>(
                                        value: position,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: AppText(position),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedPosition = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
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

                    // Confirm Password Field
                    AppFormField(
                      controller: _confirmPasswordController,
                      label: 'تأكيد كلمة المرور',
                      hint: '******',
                      prefix: const Icon(Icons.lock_outline),
                      isPassword: true,
                      suffix: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppColors.deepTeal,
                        ),
                        onPressed: _toggleConfirmPasswordVisibility,
                      ),
                      validator:
                          (value) => AppValidators.validatePasswordConfirmation(
                            value,
                            _passwordController.text,
                          ),
                    ),
                    SizedBox(height: AppDimensions.large),

                    // Register Button
                    state is AuthLoading
                        ? const Center(child: AppLoadingIndicator())
                        : AppButton(text: 'تسجيل', onPressed: _register),
                    SizedBox(height: AppDimensions.medium),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(
                          'لديك حساب بالفعل؟',
                          color: AppColors.textSecondary,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: AppText(
                            'تسجيل الدخول',
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
          );
        },
      ),
    );
  }
}
