import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/scan_service.dart';
import '../../../core/services/dependency_injector.dart';
import 'scan_history_state.dart';

class UserScanHistoryCubit extends Cubit<ScanHistoryState> {
  final ScanService _scanService;

  UserScanHistoryCubit({
    ScanService? scanService,
  })  : _scanService = scanService ?? DependencyInjector().scanService,
        super(ScanHistoryInitial());

  Future<void> loadScanHistory(String userId) async {
    try {
      emit(ScanHistoryLoading());

      final scanHistory = await _scanService.getUserScanHistory(userId);

      emit(ScanHistoryLoaded(scanHistory));
    } catch (e) {
      emit(ScanHistoryError('حدث خطأ أثناء تحميل سجل المسح: ${e.toString()}'));
    }
  }

  Future<void> refreshScanHistory(String userId) async {
    // Don't emit loading state for refresh to avoid UI flicker
    try {
      final scanHistory = await _scanService.getUserScanHistory(userId);
      emit(ScanHistoryLoaded(scanHistory));
    } catch (e) {
      emit(ScanHistoryError('حدث خطأ أثناء تحديث سجل المسح: ${e.toString()}'));
    }
  }
}
