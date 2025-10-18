import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_loading.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/core/utils/app_colors.dart';
import 'package:neqati/core/utils/app_dimensions.dart';
import 'package:neqati/features/admin/offer_management/cubit/offer_management_cubit.dart';
import 'package:neqati/features/admin/offer_management/cubit/offer_management_state.dart';
import 'package:neqati/features/admin/offer_management/presentation/screens/create_offer_screen.dart';
import 'package:neqati/features/admin/offer_management/presentation/screens/edit_offer_screen.dart';

class OffersManagementScreen extends StatefulWidget {
  const OffersManagementScreen({Key? key}) : super(key: key);

  @override
  State<OffersManagementScreen> createState() => _OffersManagementScreenState();
}

class _OffersManagementScreenState extends State<OffersManagementScreen> {
  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  void _loadOffers() {
    context.read<OfferManagementCubit>().loadOffers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.title('إدارة العروض', color: AppColors.white),
        backgroundColor: AppColors.deepTeal,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => BlocProvider.value(
                    value: context.read<OfferManagementCubit>(),
                    child: const CreateOfferScreen(),
                  ),
            ),
          );
        },
        backgroundColor: AppColors.deepTeal,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: BlocConsumer<OfferManagementCubit, OfferManagementState>(
        listener: (context, state) {
          if (state is OfferActionSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            _loadOffers();
          } else if (state is OfferManagementError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is OfferManagementLoading) {
            return const Center(child: AppLoading());
          }

          if (state is OffersLoaded) {
            final offers = state.offers;

            if (offers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppText('لا توجد عروض'),
                    const SizedBox(height: AppDimensions.medium),
                    ElevatedButton(
                      onPressed: _loadOffers,
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
              itemCount: offers.length,
              itemBuilder: (context, index) {
                final offer = offers[index];
                return _buildOfferCard(offer);
              },
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText('حدث خطأ أثناء تحميل العروض'),
                const SizedBox(height: AppDimensions.medium),
                ElevatedButton(
                  onPressed: _loadOffers,
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

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    final isActive = offer['is_active'] as bool? ?? false;
    final offerId = offer['id']?.toString() ?? '';
    return AppContainer(
      margin: const EdgeInsets.only(bottom: AppDimensions.small),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.small),
        child: Column(
          children: [
            Row(
              children: [
                // Offer image or placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? AppColors.deepTeal.withOpacity(0.1)
                            : AppColors.lightText.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        offer['image_url'] != null &&
                                offer['image_url'].toString().isNotEmpty
                            ? Image.network(
                              offer['image_url'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.local_offer,
                                  color:
                                      isActive
                                          ? AppColors.deepTeal
                                          : AppColors.lightText,
                                  size: 30,
                                );
                              },
                            )
                            : Icon(
                              Icons.local_offer,
                              color:
                                  isActive
                                      ? AppColors.deepTeal
                                      : AppColors.lightText,
                              size: 30,
                            ),
                  ),
                ),
                const SizedBox(width: AppDimensions.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppText(
                              offer['title'] ?? 'عرض',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Status indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isActive
                                      ? AppColors.successGreen.withOpacity(0.1)
                                      : AppColors.alertRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: AppText(
                              isActive ? 'مفعل' : 'غير مفعل',
                              isSmall: true,
                              color:
                                  isActive
                                      ? AppColors.successGreen
                                      : AppColors.alertRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        offer['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        isSmall: true,
                        color: AppColors.lightText,
                      ),
                      const SizedBox(height: 4),
                      if (offer['created_at'] != null)
                        AppText(
                          'تاريخ الإنشاء: ${_formatDate(offer['created_at'])}',
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
                            builder:
                                (context) => BlocProvider.value(
                                  value: context.read<OfferManagementCubit>(),
                                  child: EditOfferScreen(offer: offer),
                                ),
                          ),
                        );
                        break;
                      case 'toggle':
                        _toggleOfferStatus(offerId, !isActive);
                        break;
                      case 'delete':
                        _showDeleteDialog(offerId);
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('تعديل'),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(isActive ? 'إلغاء التفعيل' : 'تفعيل'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('حذف'),
                        ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.small),
            // Action buttons row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleOfferStatus(offerId, !isActive),
                    icon: Icon(
                      isActive ? Icons.visibility_off : Icons.visibility,
                      size: 16,
                    ),
                    label: AppText(
                      isActive ? 'إلغاء التفعيل' : 'تفعيل',
                      color: AppColors.white,
                      isSmall: true,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isActive
                              ? AppColors.alertRed
                              : AppColors.successGreen,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.small),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => BlocProvider.value(
                                value: context.read<OfferManagementCubit>(),
                                child: EditOfferScreen(offer: offer),
                              ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: AppText('تعديل', isSmall: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.deepTeal,
                      side: BorderSide(color: AppColors.deepTeal),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return '';
    }
  }

  void _toggleOfferStatus(String offerId, bool newStatus) {
    final action = newStatus ? 'تفعيل' : 'إلغاء تفعيل';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: AppText('$action العرض'),
            content: AppText('هل أنت متأكد من $action هذا العرض؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: AppText('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<OfferManagementCubit>().toggleOfferStatus(
                    offerId,
                    newStatus,
                  );
                },
                child: AppText(
                  'تأكيد',
                  color:
                      newStatus ? AppColors.successGreen : AppColors.alertRed,
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteDialog(String offerId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: AppText('حذف العرض'),
            content: AppText('هل أنت متأكد من حذف هذا العرض؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: AppText('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<OfferManagementCubit>().deleteOffer(offerId);
                },
                child: AppText('حذف', color: Colors.red),
              ),
            ],
          ),
    );
  }
}
