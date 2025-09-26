import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/services/gift_service.dart';
import 'package:neqati/features/admin/gift_management/cubit/gift_management_state.dart';

class GiftManagementCubit extends Cubit<GiftManagementState> {
  final GiftService _giftService;

  GiftManagementCubit({required GiftService giftService})
    : _giftService = giftService,
      super(GiftManagementInitial());

  // Gift Management
  Future<void> loadGifts() async {
    try {
      emit(GiftManagementLoading());

      final gifts = await _giftService.getAllGifts();

      emit(GiftsLoaded(gifts));
    } catch (e) {
      emit(GiftManagementError('Failed to load gifts: ${e.toString()}'));
    }
  }

  Future<void> createGift({
    required String name,
    required int points,
    required int stock,
    required String imageUrl,
  }) async {
    try {
      emit(GiftManagementLoading());

      final giftId = await _giftService.createGift(
        name: name,
        points: points,
        stock: stock,
        imageUrl: imageUrl,
      );

      emit(
        GiftActionSuccess(
          message: 'تم إنشاء الهدية بنجاح',
          giftId: giftId,
          action: 'create',
        ),
      );
    } catch (e) {
      emit(GiftManagementError('Failed to create gift: ${e.toString()}'));
    }
  }

  Future<void> updateGift({
    required String giftId,
    required Map<String, dynamic> giftData,
  }) async {
    try {
      emit(GiftManagementLoading());

      await _giftService.updateGift(
        giftId: giftId,
        giftData: giftData,
      );

      emit(
        GiftActionSuccess(
          message: 'تم تحديث الهدية بنجاح',
          giftId: giftId,
          action: 'update',
        ),
      );
    } catch (e) {
      emit(GiftManagementError('Failed to update gift: ${e.toString()}'));
    }
  }

  Future<void> deleteGift(String giftId) async {
    try {
      emit(GiftManagementLoading());

      await _giftService.deleteGift(giftId);

      emit(
        GiftActionSuccess(
          message: 'تم حذف الهدية بنجاح',
          giftId: giftId,
          action: 'delete',
        ),
      );
    } catch (e) {
      emit(GiftManagementError('Failed to delete gift: ${e.toString()}'));
    }
  }

  // Get gift by ID
  Future<Map<String, dynamic>?> getGiftById(String giftId) async {
    try {
      return await _giftService.getGiftById(giftId);
    } catch (e) {
      emit(GiftManagementError('Failed to get gift: ${e.toString()}'));
      return null;
    }
  }

  // Get gift requests
  Future<List<Map<String, dynamic>>> getGiftRequests(String giftId) async {
    try {
      return await _giftService.getGiftRequests(giftId);
    } catch (e) {
      emit(GiftManagementError('Failed to get gift requests: ${e.toString()}'));
      return [];
    }
  }

  // Update gift request status
  Future<void> updateGiftRequestStatus(String requestId, String status) async {
    try {
      emit(GiftManagementLoading());

      await _giftService.updateGiftRequestStatus(requestId, status);

      emit(GiftManagementInitial());
    } catch (e) {
      emit(GiftManagementError('Failed to update request status: ${e.toString()}'));
    }
  }
}
