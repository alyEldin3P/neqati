import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:neqati/features/gifts/cubit/qr_scan_cubit.dart';
import 'package:neqati/features/gifts/cubit/qr_scan_state.dart';
import '../../../../core/presentation/widgets/app_text.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dimensions.dart';
import '../../../auth/cubit/auth_cubit.dart';
import '../widgets/scan_result_dialog.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController controller;
  bool _isProcessing = false;

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
        title: AppText(
          'مسح رمز QR',
          color: AppColors.white,
          fontWeight: FontWeight.bold,
        ),
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
      body: BlocListener<QRScanCubit, QRScanState>(
        listener: (context, state) {
          if (state is QRScanSuccess) {
            _showScanResult(state.result);
          } else if (state is QRScanError) {
            _showScanResult({
              'success': false,
              'message': state.message,
              'points': 0,
              'location': '',
            });
          }
        },
        child: Stack(
          children: [
            // QR Scanner View
            MobileScanner(controller: controller, onDetect: _onDetect),

            // Overlay with scanning area
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.deepTeal, width: 2),
              ),
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
            BlocBuilder<QRScanCubit, QRScanState>(
              builder: (context, state) {
                if (state is QRScanProcessing || _isProcessing) {
                  return Container(
                    color: Colors.black54,
                    child: const Center(child: AppLoadingIndicator()),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
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
          await _processQRCode(barcode.rawValue!);
        } catch (e) {
          if (mounted) {
            _showScanResult({
              'success': false,
              'message': e.toString(),
              'points': 0,
              'location': '',
            });
          }
        } finally {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  Future<void> _processQRCode(String qrData) async {
    // Get current user ID from AuthCubit
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      throw Exception('يجب تسجيل الدخول لمسح الرموز');
    }

    final userId = authState.user.id;

    // Record scan in Supabase and get points using the cubit
    await context.read<QRScanCubit>().processQRCode(qrData, userId);
  }

  void _showScanResult(Map<String, dynamic> result) async {
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ScanResultDialog(result: result),
      );
      // Return to previous screen after dialog closes
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
