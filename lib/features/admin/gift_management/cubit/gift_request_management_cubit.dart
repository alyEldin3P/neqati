import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/services/gift_service.dart';
import 'package:neqati/features/admin/gift_management/cubit/gift_request_management_state.dart';
import 'package:neqati/features/admin/gift_management/model/gift_request.dart';
import 'dart:developer' as developer;

class GiftRequestManagementCubit extends Cubit<GiftRequestManagementState> {
  final GiftService _giftService;

  GiftRequestManagementCubit({
    GiftService? giftService,
  }) : _giftService = giftService ?? GiftService(),
        super(GiftRequestManagementInitial());

  // Load all gift requests for admin dashboard
  Future<void> loadAllGiftRequests() async {
    try {
      emit(GiftRequestManagementLoading());
      developer.log('🎁 GiftRequestManagementCubit: Loading all gift requests...');

      final response = await _giftService.getAllGiftRequests();
      final giftRequests = response.map((data) => GiftRequest.fromSupabase(data)).toList();

      developer.log('🎁 GiftRequestManagementCubit: Loaded ${giftRequests.length} gift requests');
      emit(GiftRequestManagementLoaded(giftRequests));
    } catch (e) {
      developer.log('❌ GiftRequestManagementCubit: Error loading gift requests: $e');
      emit(GiftRequestManagementError('فشل في تحميل طلبات الهدايا: $e'));
    }
  }

  // Load pending gift requests only
  Future<void> loadPendingGiftRequests() async {
    try {
      emit(GiftRequestManagementLoading());
      developer.log('🎁 GiftRequestManagementCubit: Loading pending gift requests...');

      final response = await _giftService.getAllPendingGiftRequests();
      final giftRequests = response.map((data) => GiftRequest.fromSupabase(data)).toList();

      developer.log('🎁 GiftRequestManagementCubit: Loaded ${giftRequests.length} pending gift requests');
      emit(GiftRequestManagementLoaded(giftRequests));
    } catch (e) {
      developer.log('❌ GiftRequestManagementCubit: Error loading pending gift requests: $e');
      emit(GiftRequestManagementError('فشل في تحميل طلبات الهدايا المعلقة: $e'));
    }
  }

  // Load gift requests for a specific user
  Future<void> loadUserGiftRequests(String userId) async {
    try {
      emit(UserGiftRequestsLoading());
      developer.log('🎁 GiftRequestManagementCubit: Loading gift requests for user: $userId');

      final response = await _giftService.getUserGiftRequests(userId);
      final giftRequests = response.map((data) => GiftRequest.fromSupabase(data)).toList();

      developer.log('🎁 GiftRequestManagementCubit: Loaded ${giftRequests.length} gift requests for user');
      emit(UserGiftRequestsLoaded(giftRequests: giftRequests, userId: userId));
    } catch (e) {
      developer.log('❌ GiftRequestManagementCubit: Error loading user gift requests: $e');
      emit(UserGiftRequestsError(
        message: 'فشل في تحميل طلبات الهدايا للمستخدم: $e',
        userId: userId,
      ));
    }
  }

  // Approve a gift request
  Future<void> approveGiftRequest(String requestId, {String? adminNotes}) async {
    try {
      emit(GiftRequestManagementLoading());
      developer.log('🎁 GiftRequestManagementCubit: Approving gift request: $requestId');

      await _giftService.approveGiftRequest(requestId, adminNotes ?? '');

      developer.log('🎁 GiftRequestManagementCubit: Gift request approved successfully');
      emit(GiftRequestActionSuccess(
        message: 'تم قبول طلب الهدية بنجاح وتم خصم النقاط من المستخدم',
        requestId: requestId,
        action: 'approved',
      ));

      // Reload the gift requests to show updated status
      await loadAllGiftRequests();
    } catch (e) {
      developer.log('❌ GiftRequestManagementCubit: Error approving gift request: $e');
      emit(GiftRequestManagementError('فشل في قبول طلب الهدية: $e'));
    }
  }

  // Reject a gift request
  Future<void> rejectGiftRequest(String requestId, {String? adminNotes}) async {
    try {
      emit(GiftRequestManagementLoading());
      developer.log('🎁 GiftRequestManagementCubit: Rejecting gift request: $requestId');

      await _giftService.rejectGiftRequest(requestId, adminNotes ?? '');

      developer.log('🎁 GiftRequestManagementCubit: Gift request rejected successfully');
      emit(GiftRequestActionSuccess(
        message: 'تم رفض طلب الهدية بنجاح',
        requestId: requestId,
        action: 'rejected',
      ));

      // Reload the gift requests to show updated status
      await loadAllGiftRequests();
    } catch (e) {
      developer.log('❌ GiftRequestManagementCubit: Error rejecting gift request: $e');
      emit(GiftRequestManagementError('فشل في رفض طلب الهدية: $e'));
    }
  }

  // Refresh gift requests
  Future<void> refreshGiftRequests() async {
    await loadAllGiftRequests();
  }

  // Refresh user gift requests
  Future<void> refreshUserGiftRequests(String userId) async {
    await loadUserGiftRequests(userId);
  }
}
