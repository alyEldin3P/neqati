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
  
  File? _selectedImage;
  bool _isUploadingImage = false;
  String? _currentImageUrl;
  final ImagePicker _imagePicker = ImagePicker();
  final StorageService _storageService = DependencyInjector().storageService;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing gift data
    _nameController = TextEditingController(text: widget.gift['name']?.toString() ?? '');
    _pointsController = TextEditingController(text: widget.gift['points']?.toString() ?? '0');
    _stockController = TextEditingController(text: widget.gift['stock']?.toString() ?? '0');
    _currentImageUrl = widget.gift['image_url']?.toString();
  }

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

  Future<void> _updateGift() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUploadingImage = true;
      });

      try {
        final name = _nameController.text.trim();
        final points = int.tryParse(_pointsController.text.trim()) ?? 0;
        final stock = int.tryParse(_stockController.text.trim()) ?? 0;
        
        String? imageUrl = _currentImageUrl; // Keep existing image URL
        
        // Upload new image if selected
        if (_selectedImage != null) {
          imageUrl = await _storageService.uploadImage(
            _selectedImage!,
            'gifts',
          );
        }

        final giftData = {
          'name': name,
          'points': points,
          'stock': stock,
          'image_url': imageUrl,
        };

        context.read<GiftManagementCubit>().updateGift(
          giftId: widget.gift['id']?.toString() ?? '',
          giftData: giftData,
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
                          
                          // Image Upload Section
                          _buildImageUploadSection(),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppDimensions.large),
                  
                  // Update Button
                  ElevatedButton(
                    onPressed: _isUploadingImage ? null : _updateGift,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepTeal,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.medium,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isUploadingImage
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              AppText(
                                'جاري تحديث الهدية...',
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ],
                          )
                        : AppText(
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
          child: _selectedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                )
              : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _currentImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                      ),
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
              _selectedImage != null ? 'تغيير الصورة' : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) ? 'تغيير الصورة' : 'اختيار صورة',
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
        Icon(
          Icons.add_photo_alternate,
          size: 48,
          color: AppColors.lightText,
        ),
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
