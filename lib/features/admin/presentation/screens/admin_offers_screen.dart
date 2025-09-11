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

class AdminOffersScreen extends StatefulWidget {
  const AdminOffersScreen({Key? key}) : super(key: key);

  @override
  State<AdminOffersScreen> createState() => _AdminOffersScreenState();
}

class _AdminOffersScreenState extends State<AdminOffersScreen> {
  final List<Offer> _offers = [];
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _uploadedImageUrl;
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadOffers();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  void _loadOffers() {
    context.read<AdminCubit>().loadOffers();
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
  
  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
    });
  }
  
  Future<void> _createOffer() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
      );
      return;
    }
    
    if (_selectedImage == null && _uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار صورة للعرض')),
      );
      return;
    }
    
    // Upload image if not already uploaded
    String? imageUrl = _uploadedImageUrl;
    if (_selectedImage != null && _uploadedImageUrl == null) {
      imageUrl = await _uploadImage();
      if (imageUrl == null) return;
    }
    
    await context.read<AdminCubit>().createOffer(
      title: _titleController.text,
      description: _descriptionController.text,
      imageUrl: imageUrl!,
    );
    
    _resetForm();
    Navigator.pop(context);
  }
  
  Future<void> _updateOffer(String offerId) async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
      );
      return;
    }
    
    // Upload image if a new one is selected
    String? imageUrl = _uploadedImageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage();
      if (imageUrl == null) return;
    }
    
    final offerData = <String, dynamic>{
      'title': _titleController.text,
      'description': _descriptionController.text,
    };
    
    if (imageUrl != null) {
      offerData['imageUrl'] = imageUrl;
    }
    
    await context.read<AdminCubit>().updateOffer(
      offerId: offerId,
      offerData: offerData,
    );
    
    _resetForm();
    Navigator.pop(context);
  }
  
  Future<void> _deleteOffer(String offerId) async {
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
      await context.read<AdminCubit>().deleteOffer(offerId);
    }
  }
  
  void _showCreateOfferDialog() {
    _resetForm();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة عرض جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'عنوان العرض'),
              ),
              const SizedBox(height: AppDimensions.small),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'وصف العرض'),
                maxLines: 3,
              ),
              const SizedBox(height: AppDimensions.medium),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('اختيار صورة'),
              ),
              if (_selectedImage != null) ...[
                const SizedBox(height: AppDimensions.small),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: _createOffer,
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
  
  void _showEditOfferDialog(Offer offer) {
    _titleController.text = offer.title;
    _descriptionController.text = offer.description;
    _uploadedImageUrl = offer.imageUrl;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل العرض'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'عنوان العرض'),
              ),
              const SizedBox(height: AppDimensions.small),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'وصف العرض'),
                maxLines: 3,
              ),
              const SizedBox(height: AppDimensions.medium),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('تغيير الصورة'),
              ),
              const SizedBox(height: AppDimensions.small),
              if (_selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else if (_uploadedImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _uploadedImageUrl!,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 100,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => _updateOffer(offer.id!),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العروض'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateOfferDialog,
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is OfferActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            _loadOffers();
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: AppLoadingIndicator());
          } else if (state is OffersLoaded) {
            final offers = state.offers.map((offerData) {
              return Offer.fromFirestore(
                offerData as Map<String, dynamic>, 
                offerData['id'] as String,
              );
            }).toList();
            
            if (offers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppText('لا توجد عروض حالياً'),
                    const SizedBox(height: AppDimensions.medium),
                    ElevatedButton(
                      onPressed: _showCreateOfferDialog,
                      child: const Text('إضافة عرض جديد'),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.medium),
              itemCount: offers.length,
              itemBuilder: (context, index) {
                final offer = offers[index];
                return AppContainer(
                  margin: const EdgeInsets.only(bottom: AppDimensions.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppDimensions.borderRadius),
                        ),
                        child: Image.network(
                          offer.imageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
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
                            AppText(
                              offer.title,
                              fontWeight: FontWeight.bold,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: AppDimensions.small),
                            AppText(offer.description),
                            const SizedBox(height: AppDimensions.medium),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: () => _showEditOfferDialog(offer),
                                  icon: const Icon(Icons.edit),
                                  color: AppColors.primary,
                                ),
                                IconButton(
                                  onPressed: () => _deleteOffer(offer.id!),
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
          
          return Center(
            child: ElevatedButton(
              onPressed: _loadOffers,
              child: const Text('تحميل العروض'),
            ),
          );
        },
      ),
    );
  }
}
