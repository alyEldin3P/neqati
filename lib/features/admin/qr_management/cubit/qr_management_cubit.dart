import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/services/qr_code_service.dart';
import 'package:neqati/core/services/qr_encryption_service.dart';
import 'package:neqati/features/admin/qr_management/cubit/qr_management_state.dart';

class QrManagementCubit extends Cubit<QrManagementState> {
  final QRCodeService _qrService;

  QrManagementCubit({required QRCodeService qrService})
    : _qrService = qrService,
      super(QrManagementInitial());

  // QR Code Management
  Future<void> loadQRCodes({
    int limit = 10,
    int offset = 0,
    String? searchQuery,
  }) async {
    try {
      emit(QrManagementLoading());

      final qrCodes = await _qrService.getQRCodesPaginated(
        limit: limit,
        offset: offset,
        searchQuery: searchQuery,
      );
      final totalQrCodes = await _qrService.getQRCodesCount();

      emit(QrCodesLoaded(qrCodes, totalQrCodes));
    } catch (e) {
      emit(QrManagementError('Failed to load QR codes: ${e.toString()}'));
    }
  }

  Future<void> createQRCode({
    required int points,
    required String branch,
    required int expiryDuration,
  }) async {
    try {
      emit(QrManagementLoading());

      print('🔧 Starting QR code creation with points: $points, branch: $branch, expiry: $expiryDuration');

      // First create QR code in database to get the real ID
      final qrCodeId = await _qrService.createQRCodeAdmin(
        points: points,
        branch: branch,
        expiryDuration: expiryDuration,
      );
      
      print('✅ QR code created in database with ID: $qrCodeId');
      
      // Generate QR data with the actual database ID
      final qrData = QREncryptionService.generateQRData(
        id: qrCodeId,
        points: points,
        branch: branch,
        expiryDuration: expiryDuration,
      );

      print('✅ QR data generated: $qrData');

      // Encrypt the QR data
      print('🔐 Starting encryption process...');
      final encryptedQRData = QREncryptionService.encryptQRData(qrData);
      print('✅ QR data encrypted successfully. Length: ${encryptedQRData.length}');

      // Update the QR code with the encrypted payload
      print('💾 Updating QR code with encrypted payload...');
      await _qrService.updateQRCodePayload(qrCodeId, encryptedQRData);
      print('✅ QR code updated with encrypted payload');

      emit(QrCodeCreated(qrCodeId: qrCodeId, qrCodeData: encryptedQRData));
    } catch (e) {
      print('❌ Error in createQRCode: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      emit(QrManagementError('Failed to create QR code: ${e.toString()}'));
    }
  }

  Future<void> deleteQRCode(String qrCodeId) async {
    try {
      emit(QrManagementLoading());

      await _qrService.deleteQRCode(qrCodeId);

      emit(QrCodeDeleted(qrCodeId: qrCodeId));
    } catch (e) {
      emit(QrManagementError('Failed to delete QR code: ${e.toString()}'));
    }
  }
}
