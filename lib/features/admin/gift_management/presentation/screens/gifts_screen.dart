import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_loading.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/core/utils/app_colors.dart';
import 'package:neqati/core/utils/app_dimensions.dart';
import 'package:neqati/features/admin/gift_management/cubit/gift_management_cubit.dart';
import 'package:neqati/features/admin/gift_management/cubit/gift_management_state.dart';
import 'package:neqati/features/admin/gift_management/presentation/screens/create_gift_screen.dart';
import 'package:neqati/features/admin/gift_management/presentation/screens/edit_gift_screen.dart';

class GiftsScreen extends StatefulWidget {
  const GiftsScreen({Key? key}) : super(key: key);

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen> {
  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  void _loadGifts() {
    context.read<GiftManagementCubit>().loadGifts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.title('إدارة الهدايا', color: AppColors.white),
        backgroundColor: AppColors.deepTeal,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: context.read<GiftManagementCubit>(),
                child: const CreateGiftScreen(),
              ),
            ),
          );
        },
        backgroundColor: AppColors.deepTeal,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: BlocConsumer<GiftManagementCubit, GiftManagementState>(
        listener: (context, state) {
          if (state is GiftActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            _loadGifts();
          } else if (state is GiftManagementError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is GiftManagementLoading) {
            return const Center(child: AppLoading());
          }

          if (state is GiftsLoaded) {
            final gifts = state.gifts;

            if (gifts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppText('لا توجد هدايا'),
                    const SizedBox(height: AppDimensions.medium),
                    ElevatedButton(
                      onPressed: _loadGifts,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepTeal,
                      ),
                      child: AppText('إعادة المحاولة', color: AppColors.white),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.medium),
              itemCount: gifts.length,
              itemBuilder: (context, index) {
                final gift = gifts[index];
                return _buildGiftCard(gift);
              },
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText('حدث خطأ أثناء تحميل الهدايا'),
                const SizedBox(height: AppDimensions.medium),
                ElevatedButton(
                  onPressed: _loadGifts,
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

  Widget _buildGiftCard(Map<String, dynamic> gift) {
    return AppContainer(
      margin: const EdgeInsets.only(bottom: AppDimensions.small),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.small),
        child: Row(
          children: [
            // Gift image or placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.deepTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: gift['image_url'] != null && gift['image_url'].toString().isNotEmpty
                    ? Image.network(
                        gift['image_url'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.card_giftcard,
                            color: AppColors.deepTeal,
                            size: 30,
                          );
                        },
                      )
                    : Icon(
                        Icons.card_giftcard,
                        color: AppColors.deepTeal,
                        size: 30,
                      ),
              ),
            ),
            const SizedBox(width: AppDimensions.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    gift['name'] ?? 'هدية',
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    'النقاط المطلوبة: ${gift['points']}',
                    color: AppColors.deepTeal,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    'المخزون: ${gift['stock']}',
                    isSmall: true,
                    color: AppColors.lightText,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: context.read<GiftManagementCubit>(),
                          child: EditGiftScreen(gift: gift),
                        ),
                      ),
                    );
                    break;
                  case 'delete':
                    _showDeleteDialog(gift['id']?.toString() ?? '');
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('تعديل'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('حذف'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(String giftId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText('حذف الهدية'),
        content: AppText('هل أنت متأكد من حذف هذه الهدية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: AppText('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<GiftManagementCubit>().deleteGift(giftId);
            },
            child: AppText(
              'حذف',
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
