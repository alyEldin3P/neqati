import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_form_field.dart';
import 'package:neqati/core/presentation/widgets/app_loading.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/core/utils/app_colors.dart';
import 'package:neqati/core/utils/app_dimensions.dart';
import 'package:neqati/features/admin/gift_management/cubit/gift_management_cubit.dart';
import 'package:neqati/features/admin/gift_management/cubit/gift_management_state.dart';

class EditGiftScreen extends StatefulWidget {
  final Map<String, dynamic> gift;

  const EditGiftScreen({
    super.key,
    required this.gift,
  });

  @override
  State<EditGiftScreen> createState() => _EditGiftScreenState();
}

class _EditGiftScreenState extends State<EditGiftScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _pointsController;
  late final TextEditingController _stockController;
  late final TextEditingController _imageUrlController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing gift data
    _nameController = TextEditingController(text: widget.gift['name']?.toString() ?? '');
    _pointsController = TextEditingController(text: widget.gift['points']?.toString() ?? '0');
    _stockController = TextEditingController(text: widget.gift['stock']?.toString() ?? '0');
    _imageUrlController = TextEditingController(text: widget.gift['image_url']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pointsController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _updateGift() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final points = int.tryParse(_pointsController.text.trim()) ?? 0;
      final stock = int.tryParse(_stockController.text.trim()) ?? 0;
      final imageUrl = _imageUrlController.text.trim();

      final giftData = {
        'name': name,
        'points': points,
        'stock': stock,
        'image_url': imageUrl.isEmpty ? null : imageUrl,
      };

      context.read<GiftManagementCubit>().updateGift(
        giftId: widget.gift['id']?.toString() ?? '',
        giftData: giftData,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.title('تعديل الهدية', color: AppColors.white),
        backgroundColor: AppColors.deepTeal,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<GiftManagementCubit, GiftManagementState>(
        listener: (context, state) {
          if (state is GiftActionSuccess && state.action == 'update') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is GiftManagementError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is GiftManagementLoading) {
            return const Center(child: AppLoading());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.large),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.medium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            'تعديل معلومات الهدية',
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepTeal,
                          ),
                          const SizedBox(height: AppDimensions.medium),
                          
                          // Gift Name Field
                          _buildTextField(
                            controller: _nameController,
                            label: 'اسم الهدية',
                            icon: Icons.card_giftcard,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'يرجى إدخال اسم الهدية';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: AppDimensions.medium),
                          
                          // Points Required Field
                          _buildTextField(
                            controller: _pointsController,
                            label: 'النقاط المطلوبة',
                            icon: Icons.stars,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'يرجى إدخال عدد النقاط المطلوبة';
                              }
                              final points = int.tryParse(value.trim());
                              if (points == null || points <= 0) {
                                return 'يرجى إدخال رقم صحيح أكبر من صفر';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: AppDimensions.medium),
                          
                          // Stock Field
                          _buildTextField(
                            controller: _stockController,
                            label: 'الكمية المتاحة',
                            icon: Icons.inventory,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'يرجى إدخال الكمية المتاحة';
                              }
                              final stock = int.tryParse(value.trim());
                              if (stock == null || stock < 0) {
                                return 'يرجى إدخال رقم صحيح أكبر من أو يساوي صفر';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: AppDimensions.medium),
                          
                          // Image URL Field (Optional)
                          _buildTextField(
                            controller: _imageUrlController,
                            label: 'رابط الصورة (اختياري)',
                            icon: Icons.image,
                            keyboardType: TextInputType.url,
                            validator: null, // Optional field
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppDimensions.large),
                  
                  // Update Button
                  ElevatedButton(
                    onPressed: _updateGift,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepTeal,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.medium,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: AppText(
                      'حفظ التغييرات',
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.deepTeal, size: 20),
            const SizedBox(width: 8),
            AppText(
              label,
              fontWeight: FontWeight.w500,
              color: AppColors.deepTeal,
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppFormField(
          controller: controller,
          label: label,
          hint: label,
          keyboardType: keyboardType ?? TextInputType.text,
          validator: validator,
        ),
      ],
    );
  }
}
