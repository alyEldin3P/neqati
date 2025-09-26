import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/qr_code_service.dart';
import '../../../core/services/qr_encryption_service.dart';
import '../../../core/services/dependency_injector.dart';
import 'qr_scan_state.dart';

class QRScanCubit extends Cubit<QRScanState> {
  final QRCodeService _qrCodeService;
  final Function()? onScanSuccess;

  QRScanCubit({
    QRCodeService? qrCodeService,
    this.onScanSuccess,
  })  : _qrCodeService = qrCodeService ?? DependencyInjector().qrCodeService,
        super(QRScanInitial());

  Future<void> processQRCode(String qrData, String userId) async {
    try {
      print('📱 Starting QR code processing...');
      print('📱 User ID: $userId');
      print('📱 QR Data length: ${qrData.length}');
      print('📱 QR Data preview: ${qrData.length > 50 ? qrData.substring(0, 50) + '...' : qrData}');
      
      emit(QRScanProcessing());

      // Validate and decrypt QR code
      print('🔓 Starting QR code decryption...');
      final decryptedData = QREncryptionService.decryptQRData(qrData);
      print('✅ QR code decrypted successfully: $decryptedData');

      // Record scan and get points
      print('💾 Recording QR scan...');
      final result = await _qrCodeService.recordQRScan(
        userId: userId,
        qrData: decryptedData,
      );
      print('✅ QR scan recorded successfully: $result');

      // Call success callback to refresh user data
      if (result['success'] == true && onScanSuccess != null) {
        print('🔄 Calling success callback to refresh user data...');
        onScanSuccess!();
      }

      emit(QRScanSuccess(result));
    } catch (e) {
      print('❌ Error in processQRCode: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      emit(QRScanError(e.toString()));
    }
  }

  void resetState() {
    emit(QRScanInitial());
  }
}
