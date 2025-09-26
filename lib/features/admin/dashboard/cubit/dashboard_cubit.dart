import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/services/dependency_injector.dart';
import 'package:neqati/core/services/gift_service.dart';
import 'package:neqati/core/services/offer_service.dart';
import 'package:neqati/core/services/qr_code_service.dart';
import 'package:neqati/core/services/scan_service.dart';
import 'package:neqati/core/services/user_service.dart';
import 'package:neqati/features/admin/dashboard/cubit/dashboard_state.dart';
import 'package:neqati/features/admin/dashboard/model/admin_stats.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final UserService _userService;
  final OfferService _offerService;
  final GiftService _giftService;
  final QRCodeService _qRCodeService;
  final ScanService _scanService;

  DashboardCubit()
    : _userService = DependencyInjector().userService,
      _offerService = DependencyInjector().offerService,
      _giftService = DependencyInjector().giftService,
      _qRCodeService = DependencyInjector().qrCodeService,
      _scanService = DependencyInjector().scanService,
      super(DashboardInitial());

  // Load admin dashboard statistics
  Future<void> loadAdminStats() async {
    try {
      emit(DashboardLoading());

      // Get counts from Supabase tables
      final users = await _userService.getAllUsers();
      final pendingUsers = await _userService.getPendingUsers();
      final scans = await _scanService.getRecentScans(
        365,
      ); // Get all scans from last year
      final qrCodes = await _qRCodeService.getAllQRCodes();
      final gifts = await _giftService.getAvailableGifts();
      final offers = await _offerService.getOffers();
      final pendingGiftRequests =
          await _giftService.getAllPendingGiftRequests();

      final stats = AdminStats(
        totalUsers: users.length,
        totalPendingUsers: pendingUsers.length,
        totalScans: scans.length,
        totalQrCodes: qrCodes.length,
        totalGifts: gifts.length,
        totalOffers: offers.length,
        totalPendingGiftRequests: pendingGiftRequests.length,
      );

      emit(DashboardStatsLoaded(stats));
    } catch (e) {
      emit(DashboardError('Failed to load admin statistics: ${e.toString()}'));
    }
  }
}
