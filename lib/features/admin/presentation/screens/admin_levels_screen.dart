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
import 'package:neqati/features/admin/model/level.dart';
import 'package:neqati/features/admin/presentation/screens/level_details_screen.dart';

class AdminLevelsScreen extends StatefulWidget {
  const AdminLevelsScreen({Key? key}) : super(key: key);

  @override
  State<AdminLevelsScreen> createState() => _AdminLevelsScreenState();
}

class _AdminLevelsScreenState extends State<AdminLevelsScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _startingPointsController = TextEditingController();
  final _multiplierController = TextEditingController();
  bool _isCreating = false;
  
  @override
  void initState() {
    super.initState();
    _loadLevels();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _startingPointsController.dispose();
    _multiplierController.dispose();
    super.dispose();
  }
  
  void _loadLevels() {
    context.read<AdminCubit>().loadLevels();
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
  
  Future<void> _createLevel() async {
    if (!_formKey.currentState!.validate() || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة واختيار صورة')),
      );
      return;
    }
    
    setState(() {
      _isCreating = true;
    });
    
    try {
      final imageUrl = await _uploadImage();
      if (imageUrl == null) {
        setState(() {
          _isCreating = false;
        });
        return;
      }
      
      final levelData = {
        'name': _nameController.text,
        'imageUrl': imageUrl,
        'startingPoints': int.parse(_startingPointsController.text),
        'multiplier': double.parse(_multiplierController.text),
        'createdAt': DateTime.now(),
      };
      
      await context.read<AdminCubit>().createLevel(levelData);
      
      _resetForm();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إنشاء المستوى: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }
  
  void _resetForm() {
    _nameController.clear();
    _startingPointsController.clear();
    _multiplierController.clear();
    setState(() {
      _selectedImage = null;
    });
  }
  
  void _showCreateLevelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مستوى جديد'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedImage != null)
                  Container(
                    height: 100,
                    width: 100,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('اختيار صورة'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستوى',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال اسم المستوى';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _startingPointsController,
                  decoration: const InputDecoration(
                    labelText: 'النقاط المطلوبة',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال النقاط المطلوبة';
                    }
                    if (int.tryParse(value) == null) {
                      return 'يرجى إدخال رقم صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _multiplierController,
                  decoration: const InputDecoration(
                    labelText: 'مضاعف النقاط',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال مضاعف النقاط';
                    }
                    if (double.tryParse(value) == null) {
                      return 'يرجى إدخال رقم صحيح أو عشري';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          _isCreating
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _createLevel,
                  child: const Text('إضافة'),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستويات'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateLevelDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocConsumer<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is LevelActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            if (state.action != 'load') {
              _loadLevels();
            }
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: AppLoadingIndicator());
          } else if (state is LevelsLoaded) {
            final levels = state.levels;
            
            if (levels.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppText(
                      'لا توجد مستويات حالياً',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _showCreateLevelDialog,
                      child: const AppText('إضافة مستوى جديد'),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.medium),
              itemCount: levels.length,
              itemBuilder: (context, index) {
                final level = Level.fromFirestore(levels[index], levels[index]['id']);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.medium),
                  child: AppContainer(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LevelDetailsScreen(levelId: level.id),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(AppDimensions.borderRadius),
                          ),
                          child: Image.network(
                            level.imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(Icons.error),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppDimensions.medium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                level.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AppText(
                                'النقاط المطلوبة: ${level.startingPoints}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              AppText(
                                'مضاعف النقاط: ${level.multiplier}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.alertRed),
                          onPressed: () async {
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
                              await context.read<AdminCubit>().deleteLevel(level.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppText('فشل تحميل المستويات'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadLevels,
                  child: const AppText('إعادة المحاولة'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
