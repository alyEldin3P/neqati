import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/services/offer_service.dart';
import 'package:neqati/core/services/supabase_service.dart';
import 'package:neqati/core/services/dependency_injector.dart';
import 'package:neqati/features/offers/cubit/offers_state.dart';
import 'package:neqati/features/offers/model/offer.dart';

class OffersCubit extends Cubit<OffersState> {
  final OfferService _offerService;

  OffersCubit({OfferService? offerService})
    : _offerService = offerService ?? DependencyInjector().offerService,
      super(OffersInitial());

  Future<void> loadOffers() async {
    log('🎯 OffersCubit.loadOffers() - Starting to load offers for user app');
    emit(OffersLoading());
    try {
      log('📞 Calling OfferService.getActiveOffers()');
      final offersData = await _offerService.getActiveOffers();
      
      log('📦 Raw offers data received: ${offersData.length} items');
      for (var data in offersData) {
        log('   📄 Raw Offer: ${data['title']} (ID: ${data['id']}) - is_active: ${data['is_active']}, end_date: ${data['end_date']}');
      }
      
      final offers =
          offersData
              .map(
                (data) {
                  final offer = Offer(
                    id: data['id'] as String,
                    title: data['title'] as String? ?? '',
                    description: data['description'] as String? ?? '',
                    imageUrl: data['image_url'] as String? ?? '',
                    startDate:
                        data['start_date'] != null && data['start_date'].toString().isNotEmpty
                            ? DateTime.parse(data['start_date'])
                            : DateTime.now(),
                    endDate:
                        data['end_date'] != null && data['end_date'].toString().isNotEmpty
                            ? DateTime.parse(data['end_date'])
                            : DateTime.now().add(Duration(days: 30)), // Default to 30 days from now
                    isActive: data['is_active'] as bool? ?? true, // Default to true
                  );
                  
                  log('   🎁 Mapped Offer: ${offer.title} (ID: ${offer.id}) - isActive: ${offer.isActive}, endDate: ${offer.endDate}');
                  return offer;
                },
              )
              .toList();
      
      log('✅ Final offers list: ${offers.length} offers mapped successfully');
      
      // Additional filtering check (should not be needed if service works correctly)
      final activeOffers = offers.where((offer) => offer.isActive).toList();
      log('🔍 Active offers after client-side filtering: ${activeOffers.length}');
      
      if (activeOffers.length != offers.length) {
        log('⚠️ WARNING: Found inactive offers in supposedly active offers list!');
        final inactiveOffers = offers.where((offer) => !offer.isActive).toList();
        for (var inactiveOffer in inactiveOffers) {
          log('   ❌ Inactive Offer Found: ${inactiveOffer.title} (ID: ${inactiveOffer.id}) - isActive: ${inactiveOffer.isActive}');
        }
      }
      
      emit(OffersLoaded(offers));
      log('🎉 OffersLoaded state emitted with ${offers.length} offers');
    } catch (e) {
      log('❌ Error in OffersCubit.loadOffers(): $e');
      emit(OffersError('حدث خطأ أثناء تحميل العروض. يرجى المحاولة مرة أخرى.'));
    }
  }
}
