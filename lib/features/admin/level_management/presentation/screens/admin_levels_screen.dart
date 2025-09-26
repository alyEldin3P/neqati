import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_loading.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/core/services/level_service.dart';
import 'package:neqati/core/services/storage_service.dart';
import 'package:neqati/core/utils/app_colors.dart';
import 'package:neqati/core/utils/app_dimensions.dart';
import 'package:neqati/core/services/supabase_service.dart';
import 'package:neqati/features/admin/level_management/cubit/level_management_cubit.dart';
import 'package:neqati/features/admin/level_management/cubit/level_management_state.dart';
import 'package:neqati/features/admin/level_management/model/level.dart';
import 'package:neqati/features/admin/level_management/presentation/screens/level_details_screen.dart';

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
  late StorageService _storageService;

  @override
  void initState() {
    super.initState();
    _storageService = StorageService();
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
    context.read<LevelManagementCubit>().loadLevels();
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
      final imageUrl = await _storageService.uploadImage(
        _selectedImage!,
        'levels',
      );
      return imageUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل رفع الصورة: ${e.toString()}')),
      );
      return null;
    }
  }

  Future<void> _createLevel() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage();
        if (imageUrl == null) {
          setState(() {
            _isCreating = false;
          });
          return;
        }
      }

      final levelData = {
        'name': _nameController.text,
        'image_url': imageUrl ?? '',
        'starting_points': int.parse(_startingPointsController.text),
        'multiplier': double.parse(_multiplierController.text),
        'created_at': DateTime.now().toIso8601String(),
      };

      await context.read<LevelManagementCubit>().createLevel(levelData);

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
      builder:
          (context) => AlertDialog(
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
        title: AppText.title('إدارة المستويات', color: AppColors.white),
        backgroundColor: AppColors.deepTeal,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateLevelDialog,
        backgroundColor: AppColors.deepTeal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocConsumer<LevelManagementCubit, LevelManagementState>(
        listener: (context, state) {
          if (state is LevelManagementError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is LevelActionSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            _loadLevels();
          }
        },
        builder: (context, state) {
          if (state is LevelManagementLoading) {
            return const Center(child: AppLoading());
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepTeal,
                      ),
                      child: AppText(
                        'إضافة مستوى جديد',
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.medium),
              itemCount: levels.length,
              itemBuilder: (context, index) {
                final levelData = levels[index];
                final level = Level.fromSupabase(levelData);

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.medium),
                  child: AppContainer(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  LevelDetailsScreen(levelId: level.id),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(AppDimensions.small),
                          ),
                          child:
                              level.imageUrl.isNotEmpty
                                  ? Image.network(
                                    level.imageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.emoji_events),
                                      );
                                    },
                                  )
                                  : Container(
                                    width: 80,
                                    height: 80,
                                    color: AppColors.deepTeal.withOpacity(0.1),
                                    child: Icon(
                                      Icons.emoji_events,
                                      color: AppColors.deepTeal,
                                      size: 40,
                                    ),
                                  ),
                        ),
                        const SizedBox(width: AppDimensions.medium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(level.name, fontWeight: FontWeight.bold),
                              const SizedBox(height: 4),
                              AppText(
                                'النقاط المطلوبة: ${level.startingPoints}',
                                isSmall: true,
                                color: AppColors.lightText,
                              ),
                              AppText(
                                'مضاعف النقاط: ${level.multiplier}',
                                isSmall: true,
                                color: AppColors.lightText,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('تأكيد الحذف'),
                                    content: const Text(
                                      'هل أنت متأكد من حذف هذا المستوى؟',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text('إلغاء'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: const Text('حذف'),
                                      ),
                                    ],
                                  ),
                            );

                            if (confirmed == true) {
                              await context
                                  .read<LevelManagementCubit>()
                                  .deleteLevel(level.id);
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepTeal,
                  ),
                  child: AppText('إعادة المحاولة', color: AppColors.white),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
