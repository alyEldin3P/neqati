import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_loading.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/core/utils/app_colors.dart';
import 'package:neqati/core/utils/app_dimensions.dart';
import 'package:neqati/features/admin/cubit/admin_cubit.dart';
import 'package:neqati/features/admin/cubit/admin_state.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({Key? key}) : super(key: key);

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _positionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nationalIdController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  void _createUser() {
    if (_formKey.currentState!.validate()) {
      final userData = {
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'nationalId': _nationalIdController.text.trim(),
        'position': _positionController.text.trim(),
      };

      context.read<AdminCubit>().createUser(userData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.title('إضافة مستخدم جديد', color: AppColors.white),
        backgroundColor: AppColors.deepTeal,
        centerTitle: true,
      ),
      body: BlocConsumer<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state is AdminLoading) {
            setState(() {
              _isLoading = true;
            });
          } else {
            setState(() {
              _isLoading = false;
            });

            if (state is UserActionSuccess && state.action == 'create') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
              Navigator.pop(context);
            } else if (state is AdminError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.medium),
            child: AppContainer(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.subtitle('معلومات المستخدم', color: AppColors.deepTeal),
                    const SizedBox(height: AppDimensions.medium),
                    
                    // Name field
                    _buildTextField(
                      controller: _nameController,
                      label: 'الاسم',
                      hint: 'أدخل اسم المستخدم',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال اسم المستخدم';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.medium),
                    
                    // Phone field
                    _buildTextField(
                      controller: _phoneController,
                      label: 'رقم الهاتف',
                      hint: 'أدخل رقم الهاتف',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال رقم الهاتف';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.medium),
                    
                    // Address field
                    _buildTextField(
                      controller: _addressController,
                      label: 'العنوان',
                      hint: 'أدخل عنوان المستخدم',
                      icon: Icons.location_on,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال العنوان';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.medium),
                    
                    // National ID field
                    _buildTextField(
                      controller: _nationalIdController,
                      label: 'رقم الهوية',
                      hint: 'أدخل رقم الهوية',
                      icon: Icons.badge,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال رقم الهوية';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.medium),
                    
                    // Position field
                    _buildTextField(
                      controller: _positionController,
                      label: 'الوظيفة',
                      hint: 'أدخل الوظيفة',
                      icon: Icons.work,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال الوظيفة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.large),
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepTeal,
                          padding: const EdgeInsets.symmetric(vertical: AppDimensions.medium),
                        ),
                        child: _isLoading
                            ? const AppLoading(size: 24, color: Colors.white)
                            : AppText(
                                'إنشاء المستخدم',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.small),
        ),
      ),
      validator: validator,
    );
  }
}
