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
import 'package:neqati/features/admin/model/level.dart';

class LevelDetailsScreen extends StatefulWidget {
  final String levelId;
  
  const LevelDetailsScreen({
    Key? key,
    required this.levelId,
  }) : super(key: key);

  @override
  State<LevelDetailsScreen> createState() => _LevelDetailsScreenState();
}

class _LevelDetailsScreenState extends State<LevelDetailsScreen> {
  Level? _level;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  
  final _nameController = TextEditingController();
  final _startingPointsController = TextEditingController();
  final _multiplierController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadLevelDetails();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _startingPointsController.dispose();
    _multiplierController.dispose();
    super.dispose();
  }
  
  Future<void> _loadLevelDetails() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final levelData = await context.read<AdminCubit>().getLevelById(widget.levelId);
      
      if (levelData != null) {
        setState(() {
          _level = Level.fromFirestore(levelData, widget.levelId);
          _nameController.text = _level!.name;
          _startingPointsController.text = _level!.startingPoints.toString();
          _multiplierController.text = _level!.multiplier.toString();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحميل بيانات المستوى: ${e.toString()}')),
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
      final levelImageRef = storageRef.child('levels/${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await levelImageRef.putFile(_selectedImage!);
      return await levelImageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل رفع الصورة: ${e.toString()}')),
      );
      return null;
    }
  }
  
  Future<void> _updateLevel() async {
    if (_nameController.text.isEmpty || 
        _startingPointsController.text.isEmpty || 
        _multiplierController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final levelData = <String, dynamic>{
        'name': _nameController.text,
        'startingPoints': int.parse(_startingPointsController.text),
        'multiplier': double.parse(_multiplierController.text),
      };
      
      // Upload new image if selected
      if (_selectedImage != null) {
        final imageUrl = await _uploadImage();
        if (imageUrl != null) {
          levelData['imageUrl'] = imageUrl;
        }
      }
      
      await context.read<AdminCubit>().updateLevel(
        levelId: widget.levelId,
        levelData: levelData,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث المستوى بنجاح')),
      );
      
      _loadLevelDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحديث المستوى: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteLevel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المستوى؟'),
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
        await context.read<AdminCubit>().deleteLevel(widget.levelId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المستوى بنجاح')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حذف المستوى: ${e.toString()}')),
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
        title: const Text('تفاصيل المستوى'),
        actions: [
          IconButton(
            onPressed: _deleteLevel,
            icon: const Icon(Icons.delete),
            tooltip: 'حذف المستوى',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AppLoadingIndicator())
          : _level == null
              ? const Center(child: Text('لم يتم العثور على المستوى'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Level image
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
                                      _level!.imageUrl,
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
                                  
                                  // Name field
                                  TextField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'اسم المستوى',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: AppDimensions.medium),
                                  
                                  // Starting points field
                                  TextField(
                                    controller: _startingPointsController,
                                    decoration: const InputDecoration(
                                      labelText: 'النقاط المطلوبة',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: AppDimensions.medium),
                                  
                                  // Multiplier field
                                  TextField(
                                    controller: _multiplierController,
                                    decoration: const InputDecoration(
                                      labelText: 'مضاعف النقاط',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  ),
                                  const SizedBox(height: AppDimensions.medium),
                                  
                                  // Created at info
                                  if (_level!.createdAt != null)
                                    AppText(
                                      'تاريخ الإنشاء: ${_level!.createdAt!.day}/${_level!.createdAt!.month}/${_level!.createdAt!.year}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  
                                  const SizedBox(height: AppDimensions.large),
                                  
                                  // Save button
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: _updateLevel,
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
