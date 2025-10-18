import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/gift_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/services/dependency_injector.dart';
import '../../auth/cubit/auth_cubit.dart';
import 'gift_state.dart';
import 'dart:developer' as developer;

class GiftCubit extends Cubit<GiftState> {
  final GiftService _giftService;
  final UserService _userService;
  final AuthCubit _authCubit;
  final Function()? onGiftRequestSuccess;

  GiftCubit({
    GiftService? giftService,
    UserService? userService,
    required AuthCubit authCubit,
    this.onGiftRequestSuccess,
  })  : _giftService = giftService ?? DependencyInjector().giftService,
        _userService = userService ?? DependencyInjector().userService,
        _authCubit = authCubit,
        super(GiftInitial());

  Future<void> loadGifts(String userId) async {
    try {
      developer.log('🎁 GiftCubit: Starting to load gifts for user: $userId');
      emit(GiftLoading());

      // Get user points
      developer.log('🎁 GiftCubit: Fetching user data...');
      final userData = await _userService.getUserData(userId);
      final userPoints = userData?['points'] as int? ?? 0;
      developer.log('🎁 GiftCubit: User points: $userPoints');
      developer.log('🎁 GiftCubit: User data: $userData');

      // Get available gifts
      developer.log('🎁 GiftCubit: Fetching available gifts...');
      final gifts = await _giftService.getAvailableGifts();
      developer.log('🎁 GiftCubit: Received ${gifts.length} gifts');
      
      if (gifts.isNotEmpty) {
        developer.log('🎁 GiftCubit: First gift: ${gifts[0]}');
      }

      emit(GiftLoaded(
        gifts: gifts,
        userPoints: userPoints,
      ));
      
      developer.log('🎁 GiftCubit: Successfully loaded gifts');
    } catch (e, stackTrace) {
      developer.log('❌ GiftCubit: Error loading gifts: $e');
      developer.log('❌ GiftCubit: Stack trace: $stackTrace');
      emit(GiftError('حدث خطأ أثناء تحميل الهدايا: ${e.toString()}'));
    }
  }

  Future<void> requestGift(String userId, String giftId, int giftPoints) async {
    final currentState = state;
    if (currentState is! GiftLoaded) {
      developer.log('❌ GiftCubit: Cannot request gift, current state is not GiftLoaded: ${currentState.runtimeType}');
      return;
    }

    try {
      developer.log('🎁 GiftCubit: Starting gift request - User: $userId, Gift: $giftId, Points: $giftPoints');
      emit(GiftRequestLoading());

      // Check if user is blocked (fetch fresh user data)
      developer.log('🎁 GiftCubit: Checking if user is blocked...');
      final isBlocked = await _authCubit.isUserBlocked(userId);
      if (isBlocked) {
        developer.log('❌ GiftCubit: User is blocked');
        emit(const GiftRequestError('تم حظر حسابك. لا يمكنك طلب الهدايا في الوقت الحالي'));
        return;
      }
      developer.log('✅ GiftCubit: User is not blocked, proceeding with gift request');

      // Check if user has enough points
      developer.log('🎁 GiftCubit: Checking points - User has: ${currentState.userPoints}, Required: $giftPoints');
      if (currentState.userPoints < giftPoints) {
        developer.log('❌ GiftCubit: Insufficient points');
        emit(const GiftRequestError('نقاطك غير كافية لطلب هذه الهدية'));
        return;
      }

      // Request the gift
      developer.log('🎁 GiftCubit: Calling gift service to request gift...');
      final result = await _giftService.requestGift(userId, giftId);
      developer.log('🎁 GiftCubit: Gift service result: $result');

      if (result) {
        final newUserPoints = currentState.userPoints - giftPoints;
        developer.log('🎁 GiftCubit: Gift request successful, new points: $newUserPoints');
        
        // Call success callback to refresh user data
        if (onGiftRequestSuccess != null) {
          developer.log('🔄 GiftCubit: Calling success callback to refresh user data...');
          onGiftRequestSuccess!();
        }
        
        emit(GiftRequestSuccess(
          message: 'تم طلب الهدية بنجاح. سيتم التواصل معك قريباً',
          newUserPoints: newUserPoints,
          gifts: currentState.gifts,
        ));
      } else {
        developer.log('❌ GiftCubit: Gift request failed');
        emit(const GiftRequestError('فشل طلب الهدية. يرجى المحاولة مرة أخرى'));
      }
    } catch (e, stackTrace) {
      developer.log('❌ GiftCubit: Error requesting gift: $e');
      developer.log('❌ GiftCubit: Stack trace: $stackTrace');
      emit(GiftRequestError('حدث خطأ: ${e.toString()}'));
    }
  }

  void resetToLoaded() {
    final currentState = state;
    if (currentState is GiftRequestSuccess) {
      emit(GiftLoaded(
        gifts: currentState.gifts,
        userPoints: currentState.newUserPoints,
      ));
    } else if (currentState is GiftRequestError) {
      // For error states, we need to reload the data
      // We'll emit loading state which should trigger a reload in the UI
      emit(GiftLoading());
    }
  }
}