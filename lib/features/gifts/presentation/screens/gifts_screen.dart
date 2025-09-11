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

class GiftsScreen extends StatefulWidget {
  const GiftsScreen({Key? key}) : super(key: key);

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen> {
  final FirestoreService _firestoreService = DependencyInjector().firestoreService;
  bool _isLoading = true;
  List<Map<String, dynamic>> _gifts = [];
  String? _errorMessage;
  int _userPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  Future<void> _loadGifts() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'يجب تسجيل الدخول لعرض الهدايا';
      });
      return;
    }

    try {
      // Get user points
      final userData = authState.userData;
      _userPoints = userData['points'] as int? ?? 0;
      
      // Get available gifts
      final gifts = await _firestoreService.getAvailableGifts();
      
      setState(() {
        _gifts = gifts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ أثناء تحميل الهدايا: ${e.toString()}';
      });
    }
  }

  Future<void> _requestGift(Map<String, dynamic> gift) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      _showMessage('يجب تسجيل الدخول لطلب الهدايا');
      return;
    }

    final giftId = gift['id'] as String;
    final giftPoints = gift['points'] as int? ?? 0;
    final giftName = gift['name'] as String? ?? 'هدية';

    // Check if user has enough points
    if (_userPoints < giftPoints) {
      _showMessage('نقاطك غير كافية لطلب هذه الهدية');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText('تأكيد طلب الهدية', fontWeight: FontWeight.bold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText('هل أنت متأكد من طلب هذه الهدية؟'),
            SizedBox(height: AppDimensions.small),
            AppText('$giftName - $giftPoints نقطة', fontWeight: FontWeight.bold),
            SizedBox(height: AppDimensions.small),
            AppText('سيتم خصم النقاط من رصيدك الحالي.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: AppText('إلغاء', color: AppColors.lightText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepTeal,
            ),
            child: AppText('تأكيد', color: AppColors.white),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final userId = authState.user.uid;
      final result = await _firestoreService.requestGift(userId, giftId);
      
      if (result) {
        // Update user points locally
        setState(() {
          _userPoints -= giftPoints;
        });
        
        _showMessage('تم طلب الهدية بنجاح. سيتم التواصل معك قريباً');
      } else {
        _showMessage('فشل طلب الهدية. يرجى المحاولة مرة أخرى');
      }
    } catch (e) {
      _showMessage('حدث خطأ: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText(message, color: AppColors.white),
        backgroundColor: AppColors.deepTeal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.deepTeal,
        title: AppText('الهدايا المتاحة', color: AppColors.white, fontWeight: FontWeight.bold),
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
                  _loadGifts();
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

    if (_gifts.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.card_giftcard, color: AppColors.lightTeal, size: 64),
              SizedBox(height: AppDimensions.medium),
              AppText(
                'لا توجد هدايا متاحة حالياً',
                color: AppColors.deepTeal,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: AppDimensions.small),
              AppText(
                'يرجى التحقق مرة أخرى لاحقاً',
                color: AppColors.lightText,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Points display
        Container(
          padding: EdgeInsets.all(AppDimensions.medium),
          color: AppColors.deepTeal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: AppColors.goldAccent),
              SizedBox(width: AppDimensions.small),
              AppText(
                'نقاطك الحالية: $_userPoints',
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
        ),
        
        // Gifts grid
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadGifts,
            color: AppColors.deepTeal,
            child: GridView.builder(
              padding: EdgeInsets.all(AppDimensions.medium),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: AppDimensions.medium,
                mainAxisSpacing: AppDimensions.medium,
              ),
              itemCount: _gifts.length,
              itemBuilder: (context, index) {
                final gift = _gifts[index];
                final giftName = gift['name'] as String? ?? 'هدية ${index + 1}';
                final giftPoints = gift['points'] as int? ?? 0;
                final imageUrl = gift['imageUrl'] as String?;
                final canAfford = _userPoints >= giftPoints;
                
                return AppContainer(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Gift image
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.lightTeal,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(AppDimensions.small),
                              topRight: Radius.circular(AppDimensions.small),
                            ),
                          ),
                          child: imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(AppDimensions.small),
                                    topRight: Radius.circular(AppDimensions.small),
                                  ),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.card_giftcard,
                                      color: AppColors.deepTeal,
                                      size: 48,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.card_giftcard,
                                  color: AppColors.deepTeal,
                                  size: 48,
                                ),
                        ),
                      ),
                      
                      // Gift details
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: EdgeInsets.all(AppDimensions.small),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                giftName,
                                fontWeight: FontWeight.bold,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: AppDimensions.tiny),
                              Row(
                                children: [
                                  Icon(Icons.star, color: AppColors.goldAccent, size: 16),
                                  SizedBox(width: 4),
                                  AppText(
                                    '$giftPoints نقطة',
                                    isSmall: true,
                                    color: canAfford ? AppColors.deepTeal : AppColors.alertRed,
                                  ),
                                ],
                              ),
                              Spacer(),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: canAfford ? () => _requestGift(gift) : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.deepTeal,
                                    disabledBackgroundColor: AppColors.lightText.withOpacity(0.3),
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  child: AppText(
                                    'طلب الهدية',
                                    color: AppColors.white,
                                    isSmall: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
