import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/widgets/app_text.dart';
import '../../../../core/presentation/widgets/app_container.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/dependency_injector.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dimensions.dart';
import '../../../auth/cubit/auth_cubit.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  final FirestoreService _firestoreService = DependencyInjector().firestoreService;
  bool _isLoading = true;
  List<Map<String, dynamic>> _scanHistory = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadScanHistory();
  }

  Future<void> _loadScanHistory() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'يجب تسجيل الدخول لعرض سجل المسح';
      });
      return;
    }

    try {
      final userId = authState.user.uid;
      final history = await _firestoreService.getUserScanHistory(userId);
      
      setState(() {
        _scanHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ أثناء تحميل سجل المسح: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.deepTeal,
        title: AppText('سجل المسح', color: AppColors.white, fontWeight: FontWeight.bold),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: AppLoadingIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.alertRed, size: 48),
              SizedBox(height: AppDimensions.medium),
              AppText(
                _errorMessage!,
                color: AppColors.alertRed,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimensions.large),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadScanHistory();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepTeal,
                ),
                child: AppText('إعادة المحاولة', color: AppColors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_scanHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, color: AppColors.lightTeal, size: 64),
              SizedBox(height: AppDimensions.medium),
              AppText(
                'لا يوجد سجل مسح حتى الآن',
                color: AppColors.deepTeal,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: AppDimensions.small),
              AppText(
                'قم بمسح رمز QR لكسب النقاط وستظهر هنا',
                color: AppColors.lightText,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadScanHistory,
      color: AppColors.deepTeal,
      child: ListView.builder(
        padding: EdgeInsets.all(AppDimensions.medium),
        itemCount: _scanHistory.length,
        itemBuilder: (context, index) {
          final scan = _scanHistory[index];
          final pointsEarned = scan['pointsEarned'] ?? 0;
          final branch = scan['branch'] ?? 'غير معروف';
          final scanDate = scan['scanDate'] as DateTime? ?? DateTime.now();
          
          // Format date for display
          final formattedDate = _formatDate(scanDate);
          
          return Padding(
            padding: EdgeInsets.only(bottom: AppDimensions.small),
            child: AppContainer(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.lightTeal,
                  child: Icon(Icons.qr_code, color: AppColors.deepTeal),
                ),
                title: AppText('فرع $branch', fontWeight: FontWeight.bold),
                subtitle: AppText('تم إضافة $pointsEarned نقطة', isSmall: true),
                trailing: AppText(formattedDate, isCaption: true),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
