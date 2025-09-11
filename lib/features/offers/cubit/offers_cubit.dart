import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/services/firestore_service.dart';
import 'package:neqati/core/services/dependency_injector.dart';
import 'package:neqati/features/offers/cubit/offers_state.dart';
import 'package:neqati/features/offers/model/offer.dart';

class OffersCubit extends Cubit<OffersState> {
  final FirestoreService _firestoreService;

  OffersCubit({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? DependencyInjector.resolve<FirestoreService>(),
        super(OffersInitial());

  Future<void> loadOffers() async {
    emit(OffersLoading());
    try {
      final offersData = await _firestoreService.getActiveOffers();
      final offers = offersData.map((data) => Offer(
        id: data['id'] as String,
        title: data['title'] as String? ?? '',
        description: data['description'] as String? ?? '',
        imageUrl: data['imageUrl'] as String? ?? '',
        startDate: (data['startDate'] as Timestamp).toDate(),
        endDate: (data['endDate'] as Timestamp).toDate(),
        isActive: data['isActive'] as bool? ?? false,
      )).toList();
      emit(OffersLoaded(offers));
    } catch (e) {
      emit(OffersError('حدث خطأ أثناء تحميل العروض. يرجى المحاولة مرة أخرى.'));
    }
  }
}
