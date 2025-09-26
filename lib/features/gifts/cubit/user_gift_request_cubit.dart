import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/gift_service.dart';
import '../../../core/services/dependency_injector.dart';
import '../../admin/gift_management/model/gift_request.dart';
import 'user_gift_request_state.dart';
import 'dart:developer' as developer;

class UserGiftRequestCubit extends Cubit<UserGiftRequestState> {
  final GiftService _giftService;

  UserGiftRequestCubit({
    GiftService? giftService,
  })  : _giftService = giftService ?? DependencyInjector().giftService,
        super(UserGiftRequestInitial());

  Future<void> loadUserGiftRequests(String userId) async {
    try {
      developer.log('🎁 UserGiftRequestCubit: Loading gift requests for user: $userId');
      emit(UserGiftRequestLoading());

      final giftRequestsData = await _giftService.getUserGiftRequests(userId);
      developer.log('🎁 UserGiftRequestCubit: Received ${giftRequestsData.length} gift requests');

      // Convert raw data to GiftRequest objects
      final giftRequests = giftRequestsData
          .map((data) => GiftRequest.fromSupabase(data))
          .toList();

      developer.log('🎁 UserGiftRequestCubit: Converted to ${giftRequests.length} GiftRequest objects');

      emit(UserGiftRequestLoaded(giftRequests: giftRequests));
    } catch (e, stackTrace) {
      developer.log('❌ UserGiftRequestCubit: Error loading gift requests: $e');
      developer.log('❌ UserGiftRequestCubit: Stack trace: $stackTrace');
      emit(UserGiftRequestError('حدث خطأ أثناء تحميل طلبات الهدايا: ${e.toString()}'));
    }
  }

  Future<void> deleteGiftRequest(String requestId, String userId) async {
    final currentState = state;
    if (currentState is! UserGiftRequestLoaded) {
      developer.log('❌ UserGiftRequestCubit: Cannot delete request, current state is not UserGiftRequestLoaded');
      return;
    }

    try {
      developer.log('🎁 UserGiftRequestCubit: Deleting gift request: $requestId');
      emit(UserGiftRequestDeleteLoading(requestId));

      await _giftService.deleteUserGiftRequest(requestId, userId);
      developer.log('🎁 UserGiftRequestCubit: Gift request deleted successfully');

      // Remove the deleted request from the current list
      final updatedRequests = currentState.giftRequests
          .where((request) => request.id != requestId)
          .toList();

      emit(UserGiftRequestDeleteSuccess(
        message: 'تم حذف طلب الهدية بنجاح',
        updatedGiftRequests: updatedRequests,
      ));

      // After showing success message, emit loaded state with updated list
      Future.delayed(const Duration(milliseconds: 1000), () {
        emit(UserGiftRequestLoaded(giftRequests: updatedRequests));
      });
    } catch (e, stackTrace) {
      developer.log('❌ UserGiftRequestCubit: Error deleting gift request: $e');
      developer.log('❌ UserGiftRequestCubit: Stack trace: $stackTrace');
      
      String errorMessage = 'حدث خطأ أثناء حذف طلب الهدية';
      if (e.toString().contains('Cannot delete non-pending request')) {
        errorMessage = 'لا يمكن حذف طلب الهدية بعد الموافقة عليه أو رفضه';
      } else if (e.toString().contains('Unauthorized')) {
        errorMessage = 'غير مسموح لك بحذف هذا الطلب';
      }
      
      emit(UserGiftRequestDeleteError(errorMessage));

      // Return to loaded state after showing error
      Future.delayed(const Duration(milliseconds: 2000), () {
        emit(currentState);
      });
    }
  }

  void refreshGiftRequests(String userId) {
    loadUserGiftRequests(userId);
  }
}
