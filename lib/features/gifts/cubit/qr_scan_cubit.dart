import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/qr_code_service.dart';
import '../../../core/services/qr_encryption_service.dart';
import '../../../core/services/dependency_injector.dart';
import '../../auth/cubit/auth_cubit.dart';
import 'qr_scan_state.dart';

class QRScanCubit extends Cubit<QRScanState> {
  final QRCodeService _qrCodeService;
  final AuthCubit _authCubit;
  final Function()? onScanSuccess;

  QRScanCubit({
    QRCodeService? qrCodeService,
    required AuthCubit authCubit,
    this.onScanSuccess,
  })  : _qrCodeService = qrCodeService ?? DependencyInjector().qrCodeService,
        _authCubit = authCubit,
        super(QRScanInitial());

  Future<void> processQRCode(String qrData, String userId) async {
    String errorStage = 'initialization';
    try {
      print('📱 Starting QR code processing...');
      print('📱 User ID: $userId');
      print('📱 QR Data length: ${qrData.length}');
      print('📱 QR Data preview: ${qrData.length > 50 ? qrData.substring(0, 50) + '...' : qrData}');
      
      emit(QRScanProcessing());

      // Check if user is blocked (fetch fresh user data)
      errorStage = 'user blocking check';
      print('📱 Checking if user is blocked...');
      final isBlocked = await _authCubit.isUserBlocked(userId);
      if (isBlocked) {
        print('❌ User is blocked');
        emit(QRScanError('تم حظر حسابك. لا يمكنك مسح رموز QR في الوقت الحالي'));
        return;
      }
      print('✅ User is not blocked, proceeding with QR scan');

      // Validate and decrypt QR code
      errorStage = 'QR code decryption';
      print('🔓 Starting QR code decryption...');
      print('🔓 Raw QR data: $qrData');
      final decryptedData = QREncryptionService.decryptQRData(qrData);
      print('✅ QR code decrypted successfully: $decryptedData');

      // Record scan and get points
      errorStage = 'recording QR scan';
      print('💾 Recording QR scan...');
      print('💾 User ID: $userId');
      print('💾 Decrypted data: $decryptedData');
      final result = await _qrCodeService.recordQRScan(
        userId: userId,
        qrData: decryptedData,
      );
      print('✅ QR scan recorded successfully: $result');

      // Call success callback to refresh user data
      errorStage = 'success callback';
      if (result['success'] == true && onScanSuccess != null) {
        print('🔄 Calling success callback to refresh user data...');
        onScanSuccess!();
      }

      emit(QRScanSuccess(result));
    } catch (e, stackTrace) {
      print('❌ ============ QR SCAN ERROR ============');
      print('❌ Error stage: $errorStage');
      print('❌ Error message: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ User ID: $userId');
      print('❌ QR Data length: ${qrData.length}');
      print('❌ QR Data: $qrData');
      print('❌ Stack trace:');
      print(stackTrace);
      print('❌ ========================================');
      
      // Create detailed error message for user
      final errorMessage = '''
خطأ في مسح رمز QR

المرحلة: $errorStage
التفاصيل: $e
نوع الخطأ: ${e.runtimeType}

معلومات إضافية:
- طول البيانات: ${qrData.length}
- معرف المستخدم: $userId
''';
      
      emit(QRScanError(errorMessage));
    }
  }

  void resetState() {
    emit(QRScanInitial());
  }
}
