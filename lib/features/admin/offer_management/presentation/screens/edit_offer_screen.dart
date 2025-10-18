import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_form_field.dart';
import 'package:neqati/core/presentation/widgets/app_loading.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/core/services/storage_service.dart';
import 'package:neqati/core/utils/app_colors.dart';
import 'package:neqati/core/utils/app_dimensions.dart';
import 'package:neqati/features/admin/offer_management/cubit/offer_management_cubit.dart';
import 'package:neqati/features/admin/offer_management/cubit/offer_management_state.dart';

class EditOfferScreen extends StatefulWidget {
  final Map<String, dynamic> offer;

  const EditOfferScreen({
    super.key,
    required this.offer,
  });

  @override
  State<EditOfferScreen> createState() => _EditOfferScreenState();
}

class _EditOfferScreenState extends State<EditOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isUploading = false;
  late StorageService _storageService;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _storageService = StorageService();
    // Initialize controllers with existing offer data
    _titleController = TextEditingController(text: widget.offer['title']?.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.offer['description']?.toString() ?? '');
    _existingImageUrl = widget.offer['image_url']?.toString();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      setState(() {
        _isUploading = true;
      });

      final imageUrl = await _storageService.uploadImage(
        _selectedImage!,
        'offers',
      );
      return imageUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل رفع الصورة: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText('اختر مصدر الصورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.deepTeal),
              title: AppText('الكاميرا'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.deepTeal),
              title: AppText('المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateOffer() async {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();

      // Upload new image if selected, otherwise keep existing
      String? imageUrl = _existingImageUrl;
      if (_selectedImage != null) {
        final uploadedUrl = await _uploadImage();
        if (uploadedUrl == null) {
          // Upload failed, don't proceed
          return;
        }
        imageUrl = uploadedUrl;
      }

      final offerData = {
        'title': title,
        'description': description,
        'image_url': imageUrl ?? '',
      };

      if (mounted) {
        context.read<OfferManagementCubit>().updateOffer(
          offerId: widget.offer['id']?.toString() ?? '',
          offerData: offerData,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.title('تعديل العرض', color: AppColors.white),
        backgroundColor: AppColors.deepTeal,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<OfferManagementCubit, OfferManagementState>(
        listener: (context, state) {
          if (state is OfferActionSuccess && state.action == 'update') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is OfferManagementError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is OfferManagementLoading || _isUploading) {
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
                            'تعديل معلومات العرض',
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepTeal,
                          ),
                          const SizedBox(height: AppDimensions.medium),
                          
                          // Offer Title Field
                          _buildTextField(
                            controller: _titleController,
                            label: 'عنوان العرض',
                            icon: Icons.local_offer,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'يرجى إدخال عنوان العرض';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: AppDimensions.medium),
                          
                          // Offer Description Field
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'وصف العرض',
                            icon: Icons.description,
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'يرجى إدخال وصف العرض';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: AppDimensions.medium),
                          
                          // Image Upload Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.image, color: AppColors.deepTeal, size: 20),
                                  const SizedBox(width: 8),
                                  AppText(
                                    'صورة العرض (اختياري)',
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.deepTeal,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_selectedImage != null)
                                Container(
                                  height: 150,
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.deepTeal),
                                    image: DecorationImage(
                                      image: FileImage(_selectedImage!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                                Container(
                                  height: 150,
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.deepTeal),
                                    image: DecorationImage(
                                      image: NetworkImage(_existingImageUrl!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _showImageSourceDialog,
                                      icon: const Icon(Icons.add_photo_alternate),
                                      label: AppText(
                                        _selectedImage == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)
                                            ? 'اختيار صورة'
                                            : 'تغيير الصورة',
                                        isSmall: true,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.deepTeal,
                                        side: const BorderSide(color: AppColors.deepTeal),
                                      ),
                                    ),
                                  ),
                                  if (_selectedImage != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedImage = null;
                                          _existingImageUrl = null;
                                        });
                                      },
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'حذف الصورة',
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppDimensions.large),
                  
                  // Update Button
                  ElevatedButton(
                    onPressed: _updateOffer,
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
    int? maxLines,
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
          maxLines: maxLines,
          validator: validator,
        ),
      ],
    );
  }
}
