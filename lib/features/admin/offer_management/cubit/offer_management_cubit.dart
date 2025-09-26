import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/services/offer_service.dart';
import 'package:neqati/features/admin/offer_management/cubit/offer_management_state.dart';

class OfferManagementCubit extends Cubit<OfferManagementState> {
  final OfferService _offerService;

  OfferManagementCubit({required OfferService offerService})
    : _offerService = offerService,
      super(OfferManagementInitial());

  // Offer Management
  Future<void> loadOffers() async {
    try {
      emit(OfferManagementLoading());

      final offers = await _offerService.getOffers();

      emit(OffersLoaded(offers));
    } catch (e) {
      emit(OfferManagementError('Failed to load offers: ${e.toString()}'));
    }
  }

  Future<void> createOffer({
    required String title,
    required String description,
    required String imageUrl,
  }) async {
    try {
      emit(OfferManagementLoading());

      final offerId = await _offerService.createOffer(
        title: title,
        description: description,
        imageUrl: imageUrl,
      );

      emit(
        OfferActionSuccess(
          message: 'تم إنشاء العرض بنجاح',
          offerId: offerId,
          action: 'create',
        ),
      );
    } catch (e) {
      emit(OfferManagementError('Failed to create offer: ${e.toString()}'));
    }
  }

  Future<void> updateOffer({
    required String offerId,
    required Map<String, dynamic> offerData,
  }) async {
    try {
      emit(OfferManagementLoading());

      await _offerService.updateOffer(
        offerId: offerId,
        offerData: offerData,
      );

      emit(
        OfferActionSuccess(
          message: 'تم تحديث العرض بنجاح',
          offerId: offerId,
          action: 'update',
        ),
      );
    } catch (e) {
      emit(OfferManagementError('Failed to update offer: ${e.toString()}'));
    }
  }

  Future<void> deleteOffer(String offerId) async {
    try {
      emit(OfferManagementLoading());

      await _offerService.deleteOffer(offerId);

      emit(
        OfferActionSuccess(
          message: 'تم حذف العرض بنجاح',
          offerId: offerId,
          action: 'delete',
        ),
      );
    } catch (e) {
      emit(OfferManagementError('Failed to delete offer: ${e.toString()}'));
    }
  }

  // Get offer by ID
  Future<Map<String, dynamic>?> getOfferById(String offerId) async {
    try {
      return await _offerService.getOfferById(offerId);
    } catch (e) {
      emit(OfferManagementError('Failed to get offer: ${e.toString()}'));
      return null;
    }
  }

  // Activate/Deactivate Offer
  Future<void> activateOffer(String offerId) async {
    try {
      emit(OfferManagementLoading());

      await _offerService.activateOffer(offerId);

      emit(
        OfferActionSuccess(
          message: 'تم تفعيل العرض بنجاح',
          offerId: offerId,
          action: 'activate',
        ),
      );
    } catch (e) {
      emit(OfferManagementError('Failed to activate offer: ${e.toString()}'));
    }
  }

  Future<void> deactivateOffer(String offerId) async {
    try {
      emit(OfferManagementLoading());

      await _offerService.deactivateOffer(offerId);

      emit(
        OfferActionSuccess(
          message: 'تم إلغاء تفعيل العرض بنجاح',
          offerId: offerId,
          action: 'deactivate',
        ),
      );
    } catch (e) {
      emit(OfferManagementError('Failed to deactivate offer: ${e.toString()}'));
    }
  }

  Future<void> toggleOfferStatus(String offerId, bool isActive) async {
    try {
      emit(OfferManagementLoading());

      await _offerService.toggleOfferStatus(offerId, isActive);

      final message = isActive ? 'تم تفعيل العرض بنجاح' : 'تم إلغاء تفعيل العرض بنجاح';
      final action = isActive ? 'activate' : 'deactivate';

      emit(
        OfferActionSuccess(
          message: message,
          offerId: offerId,
          action: action,
        ),
      );
    } catch (e) {
      emit(OfferManagementError('Failed to toggle offer status: ${e.toString()}'));
    }
  }
}
