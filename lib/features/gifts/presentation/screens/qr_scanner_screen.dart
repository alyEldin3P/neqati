import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/presentation/widgets/app_text.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../core/services/qr_encryption_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/dependency_injector.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dimensions.dart';
import '../../../auth/cubit/auth_cubit.dart';
import '../widgets/scan_result_dialog.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController controller;
  bool _isProcessing = false;
  final FirestoreService _firestoreService = DependencyInjector().firestoreService;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.deepTeal,
        title: AppText('مسح رمز QR', color: AppColors.white, fontWeight: FontWeight.bold),
        centerTitle: true,
        actions: [
          IconButton(
            icon:
                controller.torchEnabled
                    ? const Icon(Icons.flash_off, color: AppColors.white)
                    : const Icon(Icons.flash_on, color: AppColors.white),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // QR Scanner View
          MobileScanner(controller: controller, onDetect: _onDetect),

          // Overlay with scanning area
          Container(
            decoration: BoxDecoration(border: Border.all(color: AppColors.deepTeal, width: 2)),
            margin: EdgeInsets.all(AppDimensions.large * 2),
          ),

          // Bottom section with instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: AppColors.white,
              padding: EdgeInsets.all(AppDimensions.medium),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    'وجه الكاميرا نحو رمز QR',
                    textAlign: TextAlign.center,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepTeal,
                  ),
                  SizedBox(height: AppDimensions.small),
                  AppText(
                    'سيتم مسح الرمز تلقائياً عند اكتشافه',
                    textAlign: TextAlign.center,
                    color: AppColors.lightText,
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isProcessing) Container(color: Colors.black54, child: const Center(child: AppLoadingIndicator())),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (!_isProcessing && barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        setState(() {
          _isProcessing = true;
        });

        try {
          final result = await _processQRCode(barcode.rawValue!);

          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => ScanResultDialog(result: result),
            );
            // Return to previous screen after dialog closes
            Navigator.of(context).pop();
          }
        } catch (e) {
          if (mounted) {
            await showDialog(
              context: context,
              builder: (context) => ScanResultDialog(result: {'success': false, 'message': e.toString()}),
            );
          }
        } finally {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  Future<Map<String, dynamic>> _processQRCode(String qrData) async {
    // Validate and decrypt QR code
    final decryptedData = QREncryptionService.decryptQRData(qrData);

    if (decryptedData == null) {
      throw Exception('رمز QR غير صالح');
    }

    // Get current user ID from AuthCubit
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      throw Exception('يجب تسجيل الدخول لمسح الرموز');
    }

    final userId = authState.user.uid;

    // Record scan in Firestore and get points
    final result = await _firestoreService.recordQRScan(userId: userId, qrData: decryptedData);

    return result;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
