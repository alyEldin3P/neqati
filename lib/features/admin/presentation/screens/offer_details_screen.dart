import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_loading_indicator.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/core/utils/app_colors.dart';
import 'package:neqati/core/utils/app_dimensions.dart';
import 'package:neqati/features/admin/cubit/admin_cubit.dart';
import 'package:neqati/features/admin/cubit/admin_state.dart';
import 'package:neqati/features/admin/model/offer.dart';

class OfferDetailsScreen extends StatefulWidget {
  final String offerId;
  
  const OfferDetailsScreen({
    Key? key,
    required this.offerId,
  }) : super(key: key);

  @override
  State<OfferDetailsScreen> createState() => _OfferDetailsScreenState();
}

class _OfferDetailsScreenState extends State<OfferDetailsScreen> {
  Offer? _offer;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadOfferDetails();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _loadOfferDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final offerData = await context.read<AdminCubit>().getOfferById(widget.offerId);
      
      if (offerData != null) {
        setState(() {
          _offer = Offer.fromFirestore(offerData, widget.offerId);
          _titleController.text = _offer!.title;
          _descriptionController.text = _offer!.description;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحميل بيانات العرض: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }
  
  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;
    
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final offerImageRef = storageRef.child('offers/${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await offerImageRef.putFile(_selectedImage!);
      return await offerImageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل رفع الصورة: ${e.toString()}')),
      );
      return null;
    }
  }
  
  Future<void> _updateOffer() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final offerData = <String, dynamic>{
        'title': _titleController.text,
        'description': _descriptionController.text,
      };
      
      // Upload new image if selected
      if (_selectedImage != null) {
        final imageUrl = await _uploadImage();
        if (imageUrl != null) {
          offerData['imageUrl'] = imageUrl;
        }
      }
      
      await context.read<AdminCubit>().updateOffer(
        offerId: widget.offerId,
        offerData: offerData,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث العرض بنجاح')),
      );
      
      _loadOfferDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحديث العرض: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteOffer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا العرض؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await context.read<AdminCubit>().deleteOffer(widget.offerId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف العرض بنجاح')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حذف العرض: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل العرض'),
        actions: [
          IconButton(
            onPressed: _deleteOffer,
            icon: const Icon(Icons.delete),
            tooltip: 'حذف العرض',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AppLoadingIndicator())
          : _offer == null
              ? const Center(child: Text('لم يتم العثور على العرض'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Offer image
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppDimensions.borderRadius),
                              ),
                              child: _selectedImage != null
                                  ? Image.file(
                                      _selectedImage!,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      _offer!.imageUrl,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: 200,
                                          width: double.infinity,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.error),
                                        );
                                      },
                                    ),
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.all(AppDimensions.medium),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Change image button
                                  Center(
                                    child: ElevatedButton.icon(
                                      onPressed: _pickImage,
                                      icon: const Icon(Icons.photo_camera),
                                      label: const Text('تغيير الصورة'),
                                    ),
                                  ),
                                  const SizedBox(height: AppDimensions.medium),
                                  
                                  // Title field
                                  TextField(
                                    controller: _titleController,
                                    decoration: const InputDecoration(
                                      labelText: 'عنوان العرض',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: AppDimensions.medium),
                                  
                                  // Description field
                                  TextField(
                                    controller: _descriptionController,
                                    decoration: const InputDecoration(
                                      labelText: 'وصف العرض',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: 5,
                                  ),
                                  const SizedBox(height: AppDimensions.medium),
                                  
                                  // Created at info
                                  if (_offer!.createdAt != null)
                                    AppText(
                                      'تاريخ الإنشاء: ${_offer!.createdAt!.day}/${_offer!.createdAt!.month}/${_offer!.createdAt!.year}',
                                      color: Colors.grey[600],
                                    ),
                                  
                                  const SizedBox(height: AppDimensions.large),
                                  
                                  // Save button
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: _updateOffer,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppDimensions.large,
                                          vertical: AppDimensions.small,
                                        ),
                                      ),
                                      child: const Text(
                                        'حفظ التغييرات',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
