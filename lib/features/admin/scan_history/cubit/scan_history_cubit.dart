import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/services/scan_service.dart';
import 'package:neqati/features/admin/scan_history/cubit/scan_history_state.dart';

class ScanHistoryCubit extends Cubit<ScanHistoryState> {
  final ScanService _scanService;

  ScanHistoryCubit({required ScanService scanService})
    : _scanService = scanService,
      super(ScanHistoryInitial());

  // Scan History
  Future<void> loadScans({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      emit(ScanHistoryLoading());

      final scans = await _scanService.getScansPaginated(
        limit: limit,
        offset: offset,
      );

      final hasMore = scans.length == limit;

      emit(ScansLoaded(scans, hasMore: hasMore));
    } catch (e) {
      emit(ScanHistoryError('Failed to load scans: ${e.toString()}'));
    }
  }
}
