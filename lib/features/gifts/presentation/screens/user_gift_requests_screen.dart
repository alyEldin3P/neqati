import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/widgets/app_text.dart';
import '../../../../core/presentation/widgets/app_container.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dimensions.dart';
import '../../../auth/cubit/auth_cubit.dart';
import '../../../admin/gift_management/model/gift_request.dart';
import '../../cubit/user_gift_request_cubit.dart';
import '../../cubit/user_gift_request_state.dart';
import 'dart:developer' as developer;

class UserGiftRequestsScreen extends StatefulWidget {
  const UserGiftRequestsScreen({super.key});

  @override
  State<UserGiftRequestsScreen> createState() => _UserGiftRequestsScreenState();
}

class _UserGiftRequestsScreenState extends State<UserGiftRequestsScreen> {
  @override
  void initState() {
    super.initState();
    _loadGiftRequests();
  }

  void _loadGiftRequests() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<UserGiftRequestCubit>().loadUserGiftRequests(authState.user.id);
    }
  }

  Future<void> _deleteGiftRequest(GiftRequest giftRequest) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      _showMessage('يجب تسجيل الدخول لحذف طلبات الهدايا');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText('تأكيد حذف الطلب', fontWeight: FontWeight.bold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText('هل أنت متأكد من حذف طلب الهدية؟'),
            SizedBox(height: AppDimensions.small),
            AppText(
              '${giftRequest.giftName ?? 'الهدية'} - ${giftRequest.giftPoints ?? 0} نقطة',
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: AppDimensions.small),
            AppText(
              'يمكن حذف الطلبات في حالة الانتظار فقط.',
              color: AppColors.lightText,
              isSmall: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: AppText('إلغاء', color: AppColors.lightText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
            ),
            child: AppText('حذف', color: AppColors.white),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<UserGiftRequestCubit>().deleteGiftRequest(
        giftRequest.id,
        authState.user.id,
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText(message, color: AppColors.white),
        backgroundColor: AppColors.deepTeal,
      ),
    );
  }

  void _showGiftRequestDetails(GiftRequest giftRequest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText('تفاصيل طلب الهدية', fontWeight: FontWeight.bold),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('اسم الهدية:', giftRequest.giftName ?? 'غير محدد'),
              _buildDetailRow('النقاط المطلوبة:', '${giftRequest.giftPoints ?? 0} نقطة'),
              _buildDetailRow('حالة الطلب:', giftRequest.statusDisplayName),
              _buildDetailRow('تاريخ الطلب:', _formatDate(giftRequest.requestDate)),
              if (giftRequest.updatedAt != null)
                _buildDetailRow('تاريخ التحديث:', _formatDate(giftRequest.updatedAt!)),
              
              // Admin message section
              if (giftRequest.adminNotes != null && giftRequest.adminNotes!.isNotEmpty) ...[
                SizedBox(height: AppDimensions.medium),
                Container(
                  padding: EdgeInsets.all(AppDimensions.small),
                  decoration: BoxDecoration(
                    color: _getStatusColor(giftRequest.status).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppDimensions.small),
                    border: Border.all(
                      color: _getStatusColor(giftRequest.status).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.message,
                            color: _getStatusColor(giftRequest.status),
                            size: 20,
                          ),
                          SizedBox(width: AppDimensions.small),
                          AppText(
                            'رسالة من الإدارة',
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(giftRequest.status),
                          ),
                        ],
                      ),
                      SizedBox(height: AppDimensions.small),
                      AppText(
                        giftRequest.adminNotes!,
                        color: AppColors.darkText,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: AppText('إغلاق', color: AppColors.deepTeal),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppDimensions.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: AppText(
              label,
              fontWeight: FontWeight.bold,
              color: AppColors.deepTeal,
            ),
          ),
          Expanded(
            flex: 3,
            child: AppText(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warningOrange;
      case 'approved':
        return AppColors.successGreen;
      case 'rejected':
        return AppColors.alertRed;
      default:
        return AppColors.lightText;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
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
            onPressed: _loadGiftRequests,
            icon: Icon(Icons.refresh, color: AppColors.white),
          ),
        ],
      ),
      body: BlocListener<UserGiftRequestCubit, UserGiftRequestState>(
        listener: (context, state) {
          if (state is UserGiftRequestDeleteSuccess) {
            _showMessage(state.message);
          } else if (state is UserGiftRequestDeleteError) {
            _showMessage(state.message);
          }
        },
        child: BlocBuilder<UserGiftRequestCubit, UserGiftRequestState>(
          builder: (context, state) {
            if (state is UserGiftRequestLoading) {
              return const Center(child: AppLoadingIndicator());
            }

            if (state is UserGiftRequestError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.large),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.alertRed,
                        size: 48,
                      ),
                      SizedBox(height: AppDimensions.medium),
                      AppText(
                        state.message,
                        color: AppColors.alertRed,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppDimensions.large),
                      ElevatedButton(
                        onPressed: _loadGiftRequests,
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

            if (state is UserGiftRequestLoaded) {
              return _buildGiftRequestsContent(state);
            }

            if (state is UserGiftRequestDeleteLoading) {
              // Show loading overlay while keeping the previous content
              return const Center(child: AppLoadingIndicator());
            }

            // Handle initial state
            final authState = context.read<AuthCubit>().state;
            if (authState is! AuthAuthenticated) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.large),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.alertRed,
                        size: 48,
                      ),
                      SizedBox(height: AppDimensions.medium),
                      AppText(
                        'يجب تسجيل الدخول لعرض طلبات الهدايا',
                        color: AppColors.alertRed,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return const Center(child: AppLoadingIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildGiftRequestsContent(UserGiftRequestLoaded state) {
    if (state.giftRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.card_giftcard_outlined, color: AppColors.lightTeal, size: 64),
              SizedBox(height: AppDimensions.medium),
              AppText(
                'لا توجد طلبات هدايا',
                color: AppColors.deepTeal,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: AppDimensions.small),
              AppText(
                'لم تقم بطلب أي هدايا بعد',
                color: AppColors.lightText,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadGiftRequests(),
      color: AppColors.deepTeal,
      child: ListView.builder(
        padding: EdgeInsets.all(AppDimensions.medium),
        itemCount: state.giftRequests.length,
        itemBuilder: (context, index) {
          final giftRequest = state.giftRequests[index];
          developer.log('🎁 UserGiftRequestsScreen: Building request card $index: ${giftRequest.id}');

          return AppContainer(
            margin: EdgeInsets.only(bottom: AppDimensions.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with gift name and status
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        giftRequest.giftName ?? 'هدية غير محددة',
                        fontWeight: FontWeight.bold,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.small,
                        vertical: AppDimensions.tiny,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(giftRequest.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.small),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(giftRequest.status),
                            size: 16,
                            color: _getStatusColor(giftRequest.status),
                          ),
                          SizedBox(width: 4),
                          AppText(
                            giftRequest.statusDisplayName,
                            isSmall: true,
                            color: _getStatusColor(giftRequest.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppDimensions.small),

                // Points and date
                Row(
                  children: [
                    Icon(Icons.star, color: AppColors.goldAccent, size: 16),
                    SizedBox(width: 4),
                    AppText(
                      '${giftRequest.giftPoints ?? 0} نقطة',
                      isSmall: true,
                      color: AppColors.deepTeal,
                    ),
                    SizedBox(width: AppDimensions.medium),
                    Icon(Icons.access_time, color: AppColors.lightText, size: 16),
                    SizedBox(width: 4),
                    AppText(
                      _formatDate(giftRequest.requestDate),
                      isSmall: true,
                      color: AppColors.lightText,
                    ),
                  ],
                ),

                // Admin message if available
                if (giftRequest.adminNotes != null && giftRequest.adminNotes!.isNotEmpty) ...[
                  SizedBox(height: AppDimensions.small),
                  Container(
                    padding: EdgeInsets.all(AppDimensions.small),
                    decoration: BoxDecoration(
                      color: _getStatusColor(giftRequest.status).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppDimensions.small),
                      border: Border.all(
                        color: _getStatusColor(giftRequest.status).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.message,
                          color: _getStatusColor(giftRequest.status),
                          size: 16,
                        ),
                        SizedBox(width: AppDimensions.small),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                'رسالة من الإدارة:',
                                isSmall: true,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(giftRequest.status),
                              ),
                              SizedBox(height: 4),
                              AppText(
                                giftRequest.adminNotes!,
                                isSmall: true,
                                color: AppColors.darkText,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: AppDimensions.medium),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showGiftRequestDetails(giftRequest),
                        icon: Icon(Icons.visibility, size: 16),
                        label: AppText('عرض التفاصيل', isSmall: true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.deepTeal,
                          side: BorderSide(color: AppColors.deepTeal),
                        ),
                      ),
                    ),
                    if (giftRequest.isPending) ...[
                      SizedBox(width: AppDimensions.small),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _deleteGiftRequest(giftRequest),
                          icon: Icon(Icons.delete, size: 16),
                          label: AppText('حذف', isSmall: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.alertRed,
                            foregroundColor: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
