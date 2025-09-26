// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../../../core/presentation/widgets/app_text.dart';
// import '../../../../../core/presentation/widgets/app_container.dart';
// import '../../../../../core/presentation/widgets/app_loading_indicator.dart';
// import '../../../../../core/utils/app_colors.dart';
// import '../../../../../core/utils/app_dimensions.dart';
// import '../../cubit/gift_request_management_cubit.dart';
// import '../../cubit/gift_request_management_state.dart';
// import '../../model/gift_request.dart';

// class GiftRequestsScreen extends StatefulWidget {
//   const GiftRequestsScreen({super.key});

//   @override
//   State<GiftRequestsScreen> createState() => _GiftRequestsScreenState();
// }

// class _GiftRequestsScreenState extends State<GiftRequestsScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // Load gift requests when screen initializes
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<GiftRequestManagementCubit>().loadAllGiftRequests();
//     });
//   }

//   String _formatDate(String? dateString) {
//     if (dateString == null) return 'غير محدد';
    
//     try {
//       final date = DateTime.parse(dateString);
//       return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//     } catch (e) {
//       return 'تاريخ غير صحيح';
//     }
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return AppColors.warningOrange;
//       case 'approved':
//         return AppColors.successGreen;
//       case 'rejected':
//         return AppColors.alertRed;
//       default:
//         return AppColors.lightText;
//     }
//   }

//   String _getStatusText(String status) {
//     switch (status.toLowerCase()) {
//       case 'pending':
//         return 'معلق';
//       case 'approved':
//         return 'مقبول';
//       case 'rejected':
//         return 'مرفوض';
//       default:
//         return status;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: AppColors.deepTeal,
//         title: AppText(
//           'طلبات الهدايا',
//           color: AppColors.white,
//           fontWeight: FontWeight.bold,
//         ),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             onPressed: _loadGiftRequests,
//             icon: Icon(Icons.refresh, color: AppColors.white),
//           ),
//         ],
//       ),
//       body: _buildBody(),
//     );
//   }

//   Widget _buildBody() {
//     if (_isLoading) {
//       return const Center(child: AppLoadingIndicator());
//     }

//     if (_error != null) {
//       return Center(
//         child: Padding(
//           padding: EdgeInsets.all(AppDimensions.large),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.error_outline,
//                 color: AppColors.alertRed,
//                 size: 48,
//               ),
//               SizedBox(height: AppDimensions.medium),
//               AppText(
//                 'حدث خطأ أثناء تحميل الطلبات',
//                 color: AppColors.alertRed,
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: AppDimensions.small),
//               AppText(
//                 _error!,
//                 color: AppColors.lightText,
//                 textAlign: TextAlign.center,
//                 isSmall: true,
//               ),
//               SizedBox(height: AppDimensions.large),
//               ElevatedButton(
//                 onPressed: _loadGiftRequests,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.deepTeal,
//                 ),
//                 child: AppText('إعادة المحاولة', color: AppColors.white),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     if (_giftRequests.isEmpty) {
//       return Center(
//         child: Padding(
//           padding: EdgeInsets.all(AppDimensions.large),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.card_giftcard_outlined,
//                 color: AppColors.lightTeal,
//                 size: 64,
//               ),
//               SizedBox(height: AppDimensions.medium),
//               AppText(
//                 'لا توجد طلبات هدايا',
//                 color: AppColors.deepTeal,
//                 fontWeight: FontWeight.bold,
//               ),
//               SizedBox(height: AppDimensions.small),
//               AppText(
//                 'لم يتم تقديم أي طلبات هدايا بعد',
//                 color: AppColors.lightText,
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: _loadGiftRequests,
//       color: AppColors.deepTeal,
//       child: ListView.builder(
//         padding: EdgeInsets.all(AppDimensions.medium),
//         itemCount: _giftRequests.length,
//         itemBuilder: (context, index) {
//           final request = _giftRequests[index];
//           return _buildRequestCard(request);
//         },
//       ),
//     );
//   }

//   Widget _buildRequestCard(Map<String, dynamic> request) {
//     final user = request['users'] as Map<String, dynamic>?;
//     final gift = request['gifts'] as Map<String, dynamic>?;
//     final status = request['status'] as String? ?? 'pending';
//     final requestDate = request['request_date'] as String?;

//     return AppContainer(
//       margin: EdgeInsets.only(bottom: AppDimensions.medium),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header with status
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               AppText(
//                 'طلب هدية #${request['id'].toString().substring(0, 8)}',
//                 fontWeight: FontWeight.bold,
//               ),
//               Container(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: AppDimensions.small,
//                   vertical: AppDimensions.tiny,
//                 ),
//                 decoration: BoxDecoration(
//                   color: _getStatusColor(status).withValues(alpha: 0.1),
//                   borderRadius: BorderRadius.circular(AppDimensions.tiny),
//                   border: Border.all(color: _getStatusColor(status)),
//                 ),
//                 child: AppText(
//                   _getStatusText(status),
//                   color: _getStatusColor(status),
//                   isSmall: true,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
          
//           SizedBox(height: AppDimensions.medium),
          
//           // User info
//           if (user != null) ...[
//             Row(
//               children: [
//                 Icon(Icons.person, color: AppColors.deepTeal, size: 20),
//                 SizedBox(width: AppDimensions.small),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       AppText(
//                         user['name'] as String? ?? 'غير محدد',
//                         fontWeight: FontWeight.bold,
//                       ),
//                       if (user['email'] != null)
//                         AppText(
//                           user['email'] as String,
//                           isSmall: true,
//                           color: AppColors.lightText,
//                         ),
//                       if (user['phone_number'] != null)
//                         AppText(
//                           user['phone_number'] as String,
//                           isSmall: true,
//                           color: AppColors.lightText,
//                         ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: AppDimensions.medium),
//           ],
          
//           // Gift info
//           if (gift != null) ...[
//             Row(
//               children: [
//                 Icon(Icons.card_giftcard, color: AppColors.deepTeal, size: 20),
//                 SizedBox(width: AppDimensions.small),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       AppText(
//                         gift['name'] as String? ?? 'غير محدد',
//                         fontWeight: FontWeight.bold,
//                       ),
//                       Row(
//                         children: [
//                           Icon(Icons.star, color: AppColors.goldAccent, size: 16),
//                           SizedBox(width: 4),
//                           AppText(
//                             '${gift['points'] ?? 0} نقطة',
//                             isSmall: true,
//                             color: AppColors.deepTeal,
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: AppDimensions.medium),
//           ],
          
//           // Request date
//           Row(
//             children: [
//               Icon(Icons.access_time, color: AppColors.lightText, size: 20),
//               SizedBox(width: AppDimensions.small),
//               AppText(
//                 'تاريخ الطلب: ${_formatDate(requestDate)}',
//                 isSmall: true,
//                 color: AppColors.lightText,
//               ),
//             ],
//           ),
          
//           // Action buttons for pending requests
//           if (status.toLowerCase() == 'pending') ...[
//             SizedBox(height: AppDimensions.medium),
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () => _updateRequestStatus(
//                       request['id'] as String,
//                       'approved',
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.successGreen,
//                     ),
//                     child: AppText('قبول', color: AppColors.white),
//                   ),
//                 ),
//                 SizedBox(width: AppDimensions.medium),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () => _updateRequestStatus(
//                       request['id'] as String,
//                       'rejected',
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.alertRed,
//                     ),
//                     child: AppText('رفض', color: AppColors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }
