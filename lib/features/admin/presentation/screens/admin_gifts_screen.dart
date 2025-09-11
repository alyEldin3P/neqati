import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_loading_indicator.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/core/utils/app_colors.dart';
import 'package:neqati/core/utils/app_dimensions.dart';
import 'package:neqati/features/admin/cubit/admin_cubit.dart';
import 'package:neqati/features/admin/cubit/admin_state.dart';
import 'package:neqati/features/gifts/model/gift.dart';

class AdminGiftsScreen extends StatefulWidget {
  const AdminGiftsScreen({Key? key}) : super(key: key);

  @override
  State<AdminGiftsScreen> createState() => _AdminGiftsScreenState();
}

class _AdminGiftsScreenState extends State<AdminGiftsScreen> {
  List<Gift> _gifts = [];

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  void _loadGifts() {
    context.read<AdminCubit>().loadGifts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.deepTeal,
        title: AppText('إدارة الهدايا', color: AppColors.white, fontWeight: FontWeight.bold),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGiftForm(),
        backgroundColor: AppColors.deepTeal,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: BlocConsumer<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state is GiftActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: AppText(state.message, color: AppColors.white)),
            );
            _loadGifts();
          } else if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AppText(state.message, color: AppColors.white),
                backgroundColor: AppColors.alertRed,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: AppLoadingIndicator());
          }
          
          if (state is GiftsLoaded) {
            _gifts = state.gifts.map((giftData) {
              return Gift(
                id: giftData['id'] as String,
                name: giftData['name'] as String? ?? '',
                points: giftData['points'] as int? ?? 0,
                stock: giftData['stock'] as int? ?? 0,
                imageUrl: giftData['imageUrl'] as String?,
                createdAt: giftData['createdAt'] != null 
                  ? (giftData['createdAt'] as dynamic).toDate() 
                  : null,
              );
            }).toList();
            
            if (_gifts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.card_giftcard, size: 64, color: AppColors.lightTeal),
                    const SizedBox(height: AppDimensions.medium),
                    AppText(
                      'لا توجد هدايا',
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepTeal,
                    ),
                    const SizedBox(height: AppDimensions.small),
                    AppText(
                      'اضغط على زر الإضافة لإنشاء هدية جديدة',
                      color: AppColors.lightText,
                    ),
                  ],
                ),
              );
            }
            
            return RefreshIndicator(
              onRefresh: () async => _loadGifts(),
              color: AppColors.deepTeal,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppDimensions.medium),
                itemCount: _gifts.length,
                itemBuilder: (context, index) {
                  final gift = _gifts[index];
                  return _buildGiftCard(gift);
                },
              ),
            );
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText('اضغط على الزر أدناه لتحميل الهدايا'),
                const SizedBox(height: AppDimensions.medium),
                ElevatedButton(
                  onPressed: _loadGifts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepTeal,
                  ),
                  child: AppText('تحميل الهدايا', color: AppColors.white),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGiftCard(Gift gift) {
    return AppContainer(
      margin: const EdgeInsets.only(bottom: AppDimensions.medium),
      child: Row(
        children: [
          // Gift image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.lightTeal,
              borderRadius: BorderRadius.circular(AppDimensions.tiny),
            ),
            child: gift.imageUrl != null && gift.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.tiny),
                    child: Image.network(
                      gift.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.card_giftcard,
                        color: AppColors.deepTeal,
                        size: 32,
                      ),
                    ),
                  )
                : Icon(
                    Icons.card_giftcard,
                    color: AppColors.deepTeal,
                    size: 32,
                  ),
          ),
          const SizedBox(width: AppDimensions.medium),
          
          // Gift details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  gift.name,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: AppDimensions.tiny),
                Row(
                  children: [
                    Icon(Icons.star, color: AppColors.goldAccent, size: 16),
                    const SizedBox(width: 4),
                    AppText(
                      '${gift.points} نقطة',
                      isSmall: true,
                    ),
                    const SizedBox(width: AppDimensions.medium),
                    Icon(Icons.inventory_2_outlined, color: AppColors.deepTeal, size: 16),
                    const SizedBox(width: 4),
                    AppText(
                      'المخزون: ${gift.stock}',
                      isSmall: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          Column(
            children: [
              IconButton(
                onPressed: () => _showGiftForm(gift: gift),
                icon: Icon(Icons.edit, color: AppColors.deepTeal),
                tooltip: 'تعديل',
              ),
              IconButton(
                onPressed: () => _confirmDeleteGift(gift),
                icon: Icon(Icons.delete, color: AppColors.alertRed),
                tooltip: 'حذف',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGiftForm({Gift? gift}) {
    final isEditing = gift != null;
    final nameController = TextEditingController(text: gift?.name ?? '');
    final pointsController = TextEditingController(text: gift?.points.toString() ?? '');
    final stockController = TextEditingController(text: gift?.stock.toString() ?? '');
    final imageUrlController = TextEditingController(text: gift?.imageUrl ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText(
          isEditing ? 'تعديل هدية' : 'إضافة هدية جديدة',
          fontWeight: FontWeight.bold,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'اسم الهدية',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppDimensions.medium),
              TextField(
                controller: pointsController,
                decoration: InputDecoration(
                  labelText: 'النقاط المطلوبة',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppDimensions.medium),
              TextField(
                controller: stockController,
                decoration: InputDecoration(
                  labelText: 'المخزون المتاح',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppDimensions.medium),
              TextField(
                controller: imageUrlController,
                decoration: InputDecoration(
                  labelText: 'رابط الصورة',
                  border: OutlineInputBorder(),
                ),
              ),
              if (gift?.imageUrl != null && gift!.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.medium),
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.lightText),
                    borderRadius: BorderRadius.circular(AppDimensions.tiny),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.tiny),
                    child: Image.network(
                      gift.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(Icons.error, color: AppColors.alertRed),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: AppText('إلغاء', color: AppColors.lightText),
          ),
          ElevatedButton(
            onPressed: () {
              // Validate inputs
              final name = nameController.text.trim();
              final pointsText = pointsController.text.trim();
              final stockText = stockController.text.trim();
              final imageUrl = imageUrlController.text.trim();
              
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: AppText('يرجى إدخال اسم الهدية', color: AppColors.white)),
                );
                return;
              }
              
              int? points;
              int? stock;
              
              try {
                points = int.parse(pointsText);
                if (points < 0) throw FormatException('Points must be positive');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: AppText('يرجى إدخال قيمة صحيحة للنقاط', color: AppColors.white)),
                );
                return;
              }
              
              try {
                stock = int.parse(stockText);
                if (stock < 0) throw FormatException('Stock must be positive');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: AppText('يرجى إدخال قيمة صحيحة للمخزون', color: AppColors.white)),
                );
                return;
              }
              
              Navigator.pop(context);
              
              if (isEditing) {
                // Update existing gift
                context.read<AdminCubit>().updateGift(
                  giftId: gift.id,
                  giftData: {
                    'name': name,
                    'points': points,
                    'stock': stock,
                    'imageUrl': imageUrl.isEmpty ? null : imageUrl,
                  },
                );
              } else {
                // Create new gift
                context.read<AdminCubit>().createGift(
                  name: name,
                  points: points,
                  stock: stock,
                  imageUrl: imageUrl.isEmpty ? '' : imageUrl,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepTeal,
            ),
            child: AppText(
              isEditing ? 'تحديث' : 'إضافة',
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGift(Gift gift) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText('تأكيد الحذف', fontWeight: FontWeight.bold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText('هل أنت متأكد من حذف هذه الهدية؟'),
            const SizedBox(height: AppDimensions.small),
            AppText(gift.name, fontWeight: FontWeight.bold),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: AppText('إلغاء', color: AppColors.lightText),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminCubit>().deleteGift(gift.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
            ),
            child: AppText('حذف', color: AppColors.white),
          ),
        ],
      ),
    );
  }
}
