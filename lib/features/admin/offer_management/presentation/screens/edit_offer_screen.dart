import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_form_field.dart';
import 'package:neqati/core/presentation/widgets/app_loading.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
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
  late final TextEditingController _imageUrlController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing offer data
    _titleController = TextEditingController(text: widget.offer['title']?.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.offer['description']?.toString() ?? '');
    _imageUrlController = TextEditingController(text: widget.offer['image_url']?.toString() ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _updateOffer() {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final imageUrl = _imageUrlController.text.trim();

      final offerData = {
        'title': title,
        'description': description,
        'image_url': imageUrl.isEmpty ? null : imageUrl,
      };

      context.read<OfferManagementCubit>().updateOffer(
        offerId: widget.offer['id']?.toString() ?? '',
        offerData: offerData,
      );
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
          if (state is OfferManagementLoading) {
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
