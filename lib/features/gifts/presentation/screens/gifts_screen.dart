import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/widgets/app_text.dart';
import '../../../../core/presentation/widgets/app_container.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dimensions.dart';
import '../../../auth/cubit/auth_cubit.dart';
import '../../cubit/gift_cubit.dart';
import '../../cubit/gift_state.dart';
import 'user_gift_requests_screen.dart';
import 'dart:developer' as developer;

class GiftsScreen extends StatefulWidget {
  const GiftsScreen({super.key});

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen> {
  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  void _loadGifts() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<GiftCubit>().loadGifts(authState.user.id);
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

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: AppText('تأكيد طلب الهدية', fontWeight: FontWeight.bold),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText('هل أنت متأكد من طلب هذه الهدية؟'),
                SizedBox(height: AppDimensions.small),
                AppText(
                  '$giftName - $giftPoints نقطة',
                  fontWeight: FontWeight.bold,
                ),
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

    if (confirmed == true) {
      context.read<GiftCubit>().requestGift(
        authState.user.id,
        giftId,
        giftPoints,
      );
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
        title: AppText(
          'الهدايا المتاحة',
          color: AppColors.white,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadGifts,
            icon: Icon(Icons.refresh, color: AppColors.white),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: BlocListener<GiftCubit, GiftState>(
        listener: (context, state) {
          if (state is GiftRequestSuccess) {
            _showMessage(state.message);
            // Reset to loaded state after showing success message
            Future.delayed(const Duration(milliseconds: 1000), () {
              context.read<GiftCubit>().resetToLoaded();
            });
          } else if (state is GiftRequestError) {
            _showMessage(state.message);
            // Reset to loaded state after showing error message
            Future.delayed(const Duration(milliseconds: 1000), () {
              context.read<GiftCubit>().resetToLoaded();
            });
          } else if (state is GiftLoading) {
            // If we're in loading state and we don't have data, reload
            final authState = context.read<AuthCubit>().state;
            if (authState is AuthAuthenticated) {
              Future.delayed(const Duration(milliseconds: 100), () {
                context.read<GiftCubit>().loadGifts(authState.user.id);
              });
            }
          }
        },
        child: BlocBuilder<GiftCubit, GiftState>(
          builder: (context, state) {
            if (state is GiftLoading || state is GiftRequestLoading) {
              return const Center(child: AppLoadingIndicator());
            }

            if (state is GiftError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.large),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.alertRed,
                        size: 48,
                      ),
                      SizedBox(height: AppDimensions.medium),
                      AppText(
                        state.message,
                        color: AppColors.alertRed,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppDimensions.large),
                      ElevatedButton(
                        onPressed: _loadGifts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepTeal,
                        ),
                        child: AppText(
                          'إعادة المحاولة',
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is GiftLoaded) {
              return _buildGiftsContent(state);
            }

            if (state is GiftRequestSuccess) {
              // Show the gifts with updated user points
              return _buildGiftsContent(
                GiftLoaded(gifts: state.gifts, userPoints: state.newUserPoints),
              );
            }

            if (state is GiftRequestError) {
              // Show error message but keep the previous loaded state if available
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.large),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.alertRed,
                        size: 48,
                      ),
                      SizedBox(height: AppDimensions.medium),
                      AppText(
                        state.message,
                        color: AppColors.alertRed,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppDimensions.large),
                      ElevatedButton(
                        onPressed: _loadGifts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepTeal,
                        ),
                        child: AppText(
                          'إعادة المحاولة',
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Handle initial state
            final authState = context.read<AuthCubit>().state;
            if (authState is! AuthAuthenticated) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.large),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.alertRed,
                        size: 48,
                      ),
                      SizedBox(height: AppDimensions.medium),
                      AppText(
                        'يجب تسجيل الدخول لعرض الهدايا',
                        color: AppColors.alertRed,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return const Center(child: AppLoadingIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildGiftsContent(GiftLoaded state) {
    if (state.gifts.isEmpty) {
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
                'نقاطك الحالية: ${state.userPoints}',
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
        ),

        // My Gift Requests Button
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.medium,
            vertical: AppDimensions.small,
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UserGiftRequestsScreen(),
                ),
              );
            },
            icon: Icon(Icons.receipt_long, color: AppColors.white),
            label: AppText(
              'طلباتي من الهدايا',
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightTeal,
              minimumSize: Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.small),
              ),
            ),
          ),
        ),

        // Gifts grid
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _loadGifts(),
            color: AppColors.deepTeal,
            child: GridView.builder(
              padding: EdgeInsets.all(AppDimensions.medium),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: AppDimensions.medium,
                mainAxisSpacing: AppDimensions.medium,
              ),
              itemCount: state.gifts.length,
              itemBuilder: (context, index) {
                final gift = state.gifts[index];
                developer.log(
                  '🎁 GiftsScreen: Building gift card $index: $gift',
                );

                final giftName = gift['name'] as String? ?? 'هدية ${index + 1}';
                final giftPoints = gift['points'] as int? ?? 0;
                final imageUrl =
                    gift['image_url'] as String?; // Fixed field name
                final stock = gift['stock'] as int? ?? 0;
                final isOutOfStock = stock <= 0;
                final canAfford = state.userPoints >= giftPoints;

                developer.log(
                  '🎁 GiftsScreen: Gift $index - Name: $giftName, Points: $giftPoints, Stock: $stock, ImageURL: $imageUrl, CanAfford: $canAfford',
                );

                return Opacity(
                  opacity: isOutOfStock ? 0.4 : 1.0,
                  child: AppContainer(
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
                            child:
                                imageUrl != null
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(
                                          AppDimensions.small,
                                        ),
                                        topRight: Radius.circular(
                                          AppDimensions.small,
                                        ),
                                      ),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
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
                          flex: 3,
                          child: Padding(
                            padding: EdgeInsets.all(AppDimensions.small),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
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
                                    Icon(
                                      Icons.star,
                                      color: AppColors.goldAccent,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Flexible(
                                      child: AppText(
                                        '$giftPoints نقطة',
                                        isSmall: true,
                                        color:
                                            canAfford
                                                ? AppColors.deepTeal
                                                : AppColors.alertRed,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: AppDimensions.tiny),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                        (canAfford && !isOutOfStock)
                                            ? () => _requestGift(gift)
                                            : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.deepTeal,
                                      disabledBackgroundColor: AppColors
                                          .lightText
                                          .withValues(alpha: 0.3),
                                      padding: EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                    ),
                                    child: AppText(
                                      isOutOfStock
                                          ? 'نفذت الكمية'
                                          : 'طلب الهدية',
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
