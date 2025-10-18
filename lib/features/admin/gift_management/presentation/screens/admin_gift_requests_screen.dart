import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/presentation/widgets/app_text.dart';
import '../../../../../core/presentation/widgets/app_container.dart';
import '../../../../../core/presentation/widgets/app_loading.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_dimensions.dart';
import '../../cubit/gift_request_management_cubit.dart';
import '../../cubit/gift_request_management_state.dart';
import '../../model/gift_request.dart';

class AdminGiftRequestsScreen extends StatefulWidget {
  const AdminGiftRequestsScreen({super.key});

  @override
  State<AdminGiftRequestsScreen> createState() =>
      _AdminGiftRequestsScreenState();
}

class _AdminGiftRequestsScreenState extends State<AdminGiftRequestsScreen> {
  @override
  void initState() {
    super.initState();
    // Load gift requests when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GiftRequestManagementCubit>().loadAllGiftRequests();
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showApproveDialog(GiftRequest request) {
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: AppText('قبول طلب الهدية'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText('هل أنت متأكد من قبول طلب الهدية؟'),
                const SizedBox(height: AppDimensions.small),
                AppText(
                  'الهدية: ${request.giftName}',
                  fontWeight: FontWeight.bold,
                ),
                AppText(
                  'النقاط المطلوبة: ${request.giftPoints}',
                  fontWeight: FontWeight.bold,
                ),
                AppText(
                  'المستخدم: ${request.userName}',
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: AppText('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<GiftRequestManagementCubit>().approveGiftRequest(
                    request.id,
                    adminNotes: notesController.text.trim(),
                  );
                },
                child: AppText('قبول', color: Colors.green),
              ),
            ],
          ),
    );
  }

  void _showRejectDialog(GiftRequest request) {
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: AppText('رفض طلب الهدية'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText('هل أنت متأكد من رفض طلب الهدية؟'),
                const SizedBox(height: AppDimensions.small),
                AppText(
                  'الهدية: ${request.giftName}',
                  fontWeight: FontWeight.bold,
                ),
                AppText(
                  'النقاط المطلوبة: ${request.giftPoints}',
                  fontWeight: FontWeight.bold,
                ),
                AppText(
                  'المستخدم: ${request.userName}',
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: AppDimensions.medium),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'سبب الرفض (اختياري)',
                    hintText: 'أدخل سبب رفض الطلب',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: AppText('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<GiftRequestManagementCubit>().rejectGiftRequest(
                    request.id,
                    adminNotes: notesController.text.trim(),
                  );
                },
                child: AppText('رفض', color: Colors.red),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.deepTeal,
        title: AppText(
          'طلبات الهدايا',
          color: AppColors.white,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              context.read<GiftRequestManagementCubit>().refreshGiftRequests();
            },
            icon: Icon(Icons.refresh, color: AppColors.white),
          ),
        ],
      ),
      body:
          BlocConsumer<GiftRequestManagementCubit, GiftRequestManagementState>(
            listener: (context, state) {
              if (state is GiftRequestActionSuccess) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              } else if (state is GiftRequestManagementError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            builder: (context, state) {
              if (state is GiftRequestManagementLoading) {
                return const Center(child: AppLoading());
              }

              if (state is GiftRequestManagementError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.large),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.alertRed,
                          size: 48,
                        ),
                        const SizedBox(height: AppDimensions.medium),
                        AppText(
                          'حدث خطأ أثناء تحميل الطلبات',
                          color: AppColors.alertRed,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimensions.small),
                        AppText(
                          state.message,
                          color: AppColors.lightText,
                          textAlign: TextAlign.center,
                          isSmall: true,
                        ),
                        const SizedBox(height: AppDimensions.large),
                        ElevatedButton(
                          onPressed: () {
                            context
                                .read<GiftRequestManagementCubit>()
                                .loadAllGiftRequests();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.deepTeal,
                          ),
                          child: AppText(
                            'إعادة المحاولة',
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is GiftRequestManagementLoaded) {
                final giftRequests = state.giftRequests;

                if (giftRequests.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.large),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.card_giftcard_outlined,
                            color: AppColors.lightTeal,
                            size: 64,
                          ),
                          const SizedBox(height: AppDimensions.medium),
                          AppText(
                            'لا توجد طلبات هدايا',
                            color: AppColors.deepTeal,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: AppDimensions.small),
                          AppText(
                            'لم يتم تقديم أي طلبات هدايا بعد',
                            color: AppColors.lightText,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context
                        .read<GiftRequestManagementCubit>()
                        .refreshGiftRequests();
                  },
                  color: AppColors.deepTeal,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.medium),
                    itemCount: giftRequests.length,
                    itemBuilder: (context, index) {
                      final request = giftRequests[index];
                      return _buildRequestCard(request);
                    },
                  ),
                );
              }

              return const Center(child: AppLoading());
            },
          ),
    );
  }

  Widget _buildRequestCard(GiftRequest request) {
    final statusColor = _getStatusColor(request.status);

    return AppContainer(
      margin: const EdgeInsets.only(bottom: AppDimensions.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                'طلب هدية #${request.id.substring(0, 8)}',
                fontWeight: FontWeight.bold,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.small,
                  vertical: AppDimensions.tiny,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.tiny),
                  border: Border.all(color: statusColor),
                ),
                child: AppText(
                  request.statusDisplayName,
                  color: statusColor,
                  isSmall: true,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.medium),

          // User info
          Row(
            children: [
              Icon(Icons.person, color: AppColors.deepTeal, size: 20),
              const SizedBox(width: AppDimensions.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      request.userName ?? 'غير محدد',
                      fontWeight: FontWeight.bold,
                    ),
                    if (request.userEmail != null)
                      AppText(
                        request.userEmail!,
                        isSmall: true,
                        color: AppColors.lightText,
                      ),
                    if (request.userPhone != null)
                      AppText(
                        request.userPhone!,
                        isSmall: true,
                        color: AppColors.lightText,
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.medium),

          // Gift info
          Row(
            children: [
              Icon(Icons.card_giftcard, color: AppColors.deepTeal, size: 20),
              const SizedBox(width: AppDimensions.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      request.giftName ?? 'غير محدد',
                      fontWeight: FontWeight.bold,
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: AppColors.goldAccent, size: 16),
                        const SizedBox(width: 4),
                        AppText(
                          '${request.giftPoints ?? 0} نقطة',
                          isSmall: true,
                          color: AppColors.deepTeal,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.medium),

          // Request date
          Row(
            children: [
              Icon(Icons.access_time, color: AppColors.lightText, size: 20),
              const SizedBox(width: AppDimensions.small),
              AppText(
                'تاريخ الطلب: ${_formatDate(request.requestDate)}',
                isSmall: true,
                color: AppColors.lightText,
              ),
            ],
          ),

          // Admin notes if available
          if (request.adminNotes != null && request.adminNotes!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.small),
            Row(
              children: [
                Icon(Icons.note, color: AppColors.lightText, size: 20),
                const SizedBox(width: AppDimensions.small),
                Expanded(
                  child: AppText(
                    'ملاحظات: ${request.adminNotes}',
                    isSmall: true,
                    color: AppColors.lightText,
                  ),
                ),
              ],
            ),
          ],

          // Action buttons for pending requests
          if (request.isPending) ...[
            const SizedBox(height: AppDimensions.medium),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showApproveDialog(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: AppText('قبول', color: AppColors.white),
                  ),
                ),
                const SizedBox(width: AppDimensions.medium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showRejectDialog(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: AppText('رفض', color: AppColors.white),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
