import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_form_field.dart';
import 'package:neqati/core/presentation/widgets/app_loading.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/core/utils/app_colors.dart';
import 'package:neqati/core/utils/app_dimensions.dart';
import 'package:neqati/core/services/storage_service.dart';
import 'package:neqati/core/services/dependency_injector.dart';
import 'package:neqati/features/admin/gift_management/cubit/gift_management_cubit.dart';
import 'package:neqati/features/admin/gift_management/cubit/gift_management_state.dart';

class CreateGiftScreen extends StatefulWidget {
  const CreateGiftScreen({super.key});

  @override
  State<CreateGiftScreen> createState() => _CreateGiftScreenState();
}

class _CreateGiftScreenState extends State<CreateGiftScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pointsController = TextEditingController();
  final _stockController = TextEditingController();

  File? _selectedImage;
  bool _isUploadingImage = false;
  final ImagePicker _imagePicker = ImagePicker();
  final StorageService _storageService = DependencyInjector().storageService;

  @override
  void dispose() {
    _nameController.dispose();
    _pointsController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في اختيار الصورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createGift() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUploadingImage = true;
      });

      try {
        final name = _nameController.text.trim();
        final points = int.tryParse(_pointsController.text.trim()) ?? 0;
        final stock = int.tryParse(_stockController.text.trim()) ?? 0;

        String? imageUrl;

        // Upload image if selected
        if (_selectedImage != null) {
          imageUrl = await _storageService.uploadImage(
            _selectedImage!,
            'gifts',
          );
        }

        // Create gift with uploaded image URL
        context.read<GiftManagementCubit>().createGift(
          name: name,
          points: points,
          stock: stock,
          imageUrl: imageUrl ?? '',
        );
      } catch (e) {
        setState(() {
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في رفع الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.title('إنشاء هدية جديدة', color: AppColors.white),
        backgroundColor: AppColors.deepTeal,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<GiftManagementCubit, GiftManagementState>(
        listener: (context, state) {
          if (state is GiftActionSuccess && state.action == 'create') {
            setState(() {
              _isUploadingImage = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is GiftManagementError) {
            setState(() {
              _isUploadingImage = false;
            });
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
                            'معلومات الهدية',
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

                          // Image Upload Section
                          _buildImageUploadSection(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.large),

                  // Create Button
                  ElevatedButton(
                    onPressed: _isUploadingImage ? null : _createGift,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepTeal,
                      disabledBackgroundColor: AppColors.lightText,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.medium,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _isUploadingImage
                            ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AppText(
                                  'جاري إنشاء الهدية...',
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            )
                            : AppText(
                              'إنشاء الهدية',
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

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image, color: AppColors.deepTeal, size: 20),
            const SizedBox(width: 8),
            AppText(
              'صورة الهدية (اختياري)',
              fontWeight: FontWeight.w500,
              color: AppColors.deepTeal,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Image preview or placeholder
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.lightTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.lightTeal),
          ),
          child:
              _selectedImage != null
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                  : _buildImagePlaceholder(),
        ),

        const SizedBox(height: 12),

        // Image action button
        Center(
          child: OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_library),
            label: AppText(
              _selectedImage != null ? 'تغيير الصورة' : 'اختيار صورة',
              isSmall: true,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.deepTeal,
              side: BorderSide(color: AppColors.deepTeal),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 48, color: AppColors.lightText),
        const SizedBox(height: 8),
        AppText(
          'اضغط لاختيار صورة الهدية',
          color: AppColors.lightText,
          isSmall: true,
        ),
      ],
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
