import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/services/user_service.dart';
import '../../../../core/presentation/widgets/app_text.dart';
import '../../../../core/presentation/widgets/app_container.dart';
import '../../../../core/presentation/widgets/app_form_field.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/dependency_injector.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dimensions.dart';
import '../../../auth/cubit/auth_cubit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late String _position;
  late String _level;
  late int _points;
  late String _phoneNumber;
  late String _nationalId;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      final userData = authState.userData;

      _nameController = TextEditingController(
        text: userData['name'] as String? ?? '',
      );
      _addressController = TextEditingController(
        text: userData['address'] as String? ?? '',
      );
      _position = userData['position'] as String? ?? 'مقاول';
      _level = userData['level'] as String? ?? 'مبتدئ';
      _points = userData['points'] as int? ?? 0;
      _phoneNumber = userData['phoneNumber'] as String? ?? '';
      _nationalId = userData['nationalId'] as String? ?? '';
    } else {
      _nameController = TextEditingController();
      _addressController = TextEditingController();
      _position = 'مقاول';
      _level = 'مبتدئ';
      _points = 0;
      _phoneNumber = '';
      _nationalId = '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      _showMessage('يجب تسجيل الدخول لتحديث الملف الشخصي');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = authState.user.id;
      await DependencyInjector().userService.updateUserData(userId, {
        'name': _nameController.text,
        'address': _addressController.text,
        'position': _position,
      });

      // Update the AuthCubit state with new user data
      await context.read<AuthCubit>().refreshUserData();

      setState(() => _isEditing = false);
      _showMessage('تم تحديث الملف الشخصي بنجاح');
    } catch (e) {
      _showMessage('حدث خطأ أثناء تحديث الملف الشخصي: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText(message, color: AppColors.white),
        backgroundColor: AppColors.deepTeal,
      ),
    );
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: AppText('تسجيل الخروج', fontWeight: FontWeight.bold),
            content: AppText('هل أنت متأكد من أنك تريد تسجيل الخروج؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: AppText('إلغاء', color: AppColors.lightText),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepTeal,
                ),
                child: AppText('تسجيل الخروج', color: AppColors.white),
              ),
            ],
          ),
    );

    if (shouldLogout == true) {
      try {
        await context.read<AuthCubit>().signOut();
        if (mounted) {
          _showMessage('تم تسجيل الخروج بنجاح');
        }
      } catch (e) {
        if (mounted) {
          _showMessage('حدث خطأ أثناء تسجيل الخروج: ${e.toString()}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.deepTeal,
        title: AppText(
          'الملف الشخصي',
          color: AppColors.white,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.white),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return _buildProfileContent(state);
          } else {
            return const Center(
              child: AppText('يجب تسجيل الدخول لعرض الملف الشخصي'),
            );
          }
        },
      ),
    );
  }

  Widget _buildProfileContent(AuthAuthenticated state) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header with points and level
          AppContainer(
            backgroundColor: AppColors.deepTeal,
            padding: EdgeInsets.all(AppDimensions.large),
            child: Column(
              children: [
                // User avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.deepTeal,
                  ),
                ),
                SizedBox(height: AppDimensions.medium),

                // User name
                AppText(
                  _nameController.text,
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: AppDimensions.small),

                // Position
                AppText(_position, color: AppColors.white.withOpacity(0.8)),
                SizedBox(height: AppDimensions.medium),

                // Points and level
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildInfoChip(
                      icon: Icons.star,
                      label: 'النقاط',
                      value: '$_points',
                      color: AppColors.goldAccent,
                    ),
                    SizedBox(width: AppDimensions.large),
                    _buildInfoChip(
                      icon: Icons.trending_up,
                      label: 'المستوى',
                      value: _level,
                      color: AppColors.lightTeal,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppDimensions.large),

          // Profile details
          AppText.subtitle('معلومات الحساب', color: AppColors.deepTeal),
          SizedBox(height: AppDimensions.medium),

          if (_isEditing) _buildEditForm() else _buildProfileDetails(),
          AppContainer(
            padding: EdgeInsets.all(AppDimensions.medium),
            onTap: _logout,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.title('تسجيل الخروج', color: AppColors.primary),
                const Icon(Icons.logout, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 4),
            AppText(value, color: AppColors.white, fontWeight: FontWeight.bold),
          ],
        ),
        SizedBox(height: 4),
        AppText(label, color: AppColors.white.withOpacity(0.8), isSmall: true),
      ],
    );
  }

  Widget _buildProfileDetails() {
    return AppContainer(
      child: Column(
        children: [
          _buildProfileDetailItem(
            icon: Icons.person,
            label: 'الاسم',
            value: _nameController.text,
          ),
          Divider(color: AppColors.lightText.withOpacity(0.2)),
          _buildProfileDetailItem(
            icon: Icons.location_on,
            label: 'العنوان',
            value: _addressController.text,
          ),
          Divider(color: AppColors.lightText.withOpacity(0.2)),
          _buildProfileDetailItem(
            icon: Icons.phone,
            label: 'رقم الهاتف',
            value: _phoneNumber,
          ),
          Divider(color: AppColors.lightText.withOpacity(0.2)),
          _buildProfileDetailItem(
            icon: Icons.badge,
            label: 'رقم الهوية',
            value: _nationalId,
          ),
          Divider(color: AppColors.lightText.withOpacity(0.2)),
          _buildProfileDetailItem(
            icon: Icons.work,
            label: 'المهنة',
            value: _position,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimensions.small),
      child: Row(
        children: [
          Icon(icon, color: AppColors.deepTeal, size: 20),
          SizedBox(width: AppDimensions.small),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(label, color: AppColors.lightText, isSmall: true),
              AppText(value.isEmpty ? '-' : value, fontWeight: FontWeight.bold),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: AppContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'يمكنك تعديل المعلومات التالية:',
              color: AppColors.lightText,
              isSmall: true,
            ),
            SizedBox(height: AppDimensions.medium),

            // Name field
            AppFormField(
              controller: _nameController,
              label: 'الاسم',
              hint: 'أدخل الاسم',
              prefix: Icon(Icons.person),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال الاسم';
                }
                return null;
              },
            ),
            SizedBox(height: AppDimensions.medium),

            // Address field
            AppFormField(
              controller: _addressController,
              label: 'العنوان',
              hint: 'أدخل العنوان',
              prefix: Icon(Icons.location_on),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال العنوان';
                }
                return null;
              },
            ),
            SizedBox(height: AppDimensions.medium),

            // Position dropdown
            AppText(
              'المهنة',
              color: AppColors.deepTeal,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: AppDimensions.tiny),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightText.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(AppDimensions.small),
              ),
              padding: EdgeInsets.symmetric(horizontal: AppDimensions.small),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _position,
                  items:
                      ['مقاول', 'مهندس', 'فني'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: AppText(value),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _position = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: AppDimensions.large),

            // Non-editable fields
            AppText(
              'معلومات لا يمكن تعديلها:',
              color: AppColors.lightText,
              isSmall: true,
            ),
            SizedBox(height: AppDimensions.medium),

            // Phone number (non-editable)
            _buildNonEditableField(
              icon: Icons.phone,
              label: 'رقم الهاتف',
              value: _phoneNumber,
            ),
            SizedBox(height: AppDimensions.medium),

            // National ID (non-editable)
            _buildNonEditableField(
              icon: Icons.badge,
              label: 'رقم الهوية',
              value: _nationalId,
            ),
            SizedBox(height: AppDimensions.large),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : () => setState(() => _isEditing = false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.deepTeal),
                      padding: EdgeInsets.symmetric(
                        vertical: AppDimensions.medium,
                      ),
                    ),
                    child: AppText('إلغاء', color: AppColors.deepTeal),
                  ),
                ),
                SizedBox(width: AppDimensions.medium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepTeal,
                      padding: EdgeInsets.symmetric(
                        vertical: AppDimensions.medium,
                      ),
                    ),
                    child:
                        _isLoading
                            ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : AppText('حفظ', color: AppColors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNonEditableField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightText.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.small),
      ),
      padding: EdgeInsets.all(AppDimensions.medium),
      child: Row(
        children: [
          Icon(icon, color: AppColors.lightText, size: 20),
          SizedBox(width: AppDimensions.small),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(label, color: AppColors.lightText, isSmall: true),
              AppText(value.isEmpty ? '-' : value, fontWeight: FontWeight.bold),
            ],
          ),
        ],
      ),
    );
  }
}
