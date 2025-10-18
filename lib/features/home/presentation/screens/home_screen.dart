import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/features/admin/dashboard/presentation/screens/admin_dashboard_screen.dart';
import 'package:neqati/features/admin/qr_management/presentation/screens/qr_codes_screen.dart';
import 'package:neqati/features/admin/user_management/cubit/user_management_cubit.dart';
import 'package:neqati/features/admin/user_management/presentation/screens/users_screen.dart';

import '../../../../core/const/branches.dart';
import '../../../../core/presentation/widgets/app_container.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../core/presentation/widgets/app_text.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dimensions.dart';
import '../../../auth/cubit/auth_cubit.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../gifts/cubit/gift_cubit.dart';
import '../../../gifts/cubit/gift_state.dart';
import '../../../gifts/cubit/scan_history_cubit.dart';
import '../../../gifts/cubit/scan_history_state.dart';
import '../../../gifts/presentation/screens/gifts_screen.dart';
import '../../../gifts/presentation/screens/qr_scanner_screen.dart';
import '../../../gifts/presentation/screens/scan_history_screen.dart';
import '../../../levels/presentation/screens/levels_screen.dart';
import '../../../offers/cubit/offers_cubit.dart';
import '../../../offers/cubit/offers_state.dart';
import '../../../offers/presentation/screens/offers_screen.dart';
import '../widgets/app_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  final bool isAdmin;

  const HomeScreen({Key? key, this.isAdmin = false}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Helper method to format time ago
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'الآن';
    }
  }

  @override
  void initState() {
    super.initState();
    dev.log('HomeScreen: initState called, isAdmin: ${widget.isAdmin}');

    // Load gifts and offers data for user home screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated && !widget.isAdmin) {
        // Load gifts and offers for regular users
        context.read<GiftCubit>().loadGifts(authState.user.id);
        context.read<OffersCubit>().loadOffers();
        
        // Load scan history for recent scans section
        context.read<UserScanHistoryCubit>().loadScanHistory(authState.user.id);
      }
    });

    // Ensure auth state is up-to-date
    if (widget.isAdmin) {
      dev.log(
        'HomeScreen: Admin user detected, setting up post-frame callback',
      );
      // If admin, make sure we're ready to show admin screens
      WidgetsBinding.instance.addPostFrameCallback((_) {
        dev.log('HomeScreen: Post-frame callback executed');
        final authState = context.read<AuthCubit>().state;
        dev.log('HomeScreen: Current auth state: ${authState.runtimeType}');

        if (authState is AuthAuthenticated) {
          dev.log(
            'HomeScreen: User is authenticated, isAdmin: ${authState.isAdmin}',
          );
          // Refresh user data to ensure we have the latest admin status
          context.read<AuthCubit>().refreshUserData();
        } else {
          dev.log(
            'HomeScreen: User is not in authenticated state: ${authState.runtimeType}',
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softWhite,

      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return _buildBody(state);
          } else {
            return const Center(child: AppLoadingIndicator());
          }
        },
      ),
      bottomNavigationBar: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final isAdmin =
              authState is AuthAuthenticated
                  ? authState.isAdmin
                  : widget.isAdmin;
          return AppBottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            isAdmin: isAdmin,
          );
        },
      ),
      floatingActionButton: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final isAdmin =
              authState is AuthAuthenticated
                  ? authState.isAdmin
                  : widget.isAdmin;
          if (_currentIndex == 1 && !isAdmin) {
            return FloatingActionButton(
              backgroundColor: AppColors.deepTeal,
              child: const Icon(Icons.qr_code_scanner, color: AppColors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const QRScannerScreen(),
                  ),
                );
              },
            );
          }
          // Return an empty container when no FAB is needed
          return Container();
        },
      ),
    );
  }

  Widget _buildBody(AuthAuthenticated state) {
    // Use the admin status from the state, which is more up-to-date than the widget property
    final isAdmin = state.isAdmin;

    if (isAdmin) {
      return _buildAdminScreen(state, _currentIndex);
    } else {
      return _buildUserScreen(state, _currentIndex);
    }
  }

  Widget _buildUserScreen(AuthAuthenticated state, int index) {
    switch (index) {
      case 0:
        return _buildUserHomeScreen(state);
      case 1:
        return _buildScanHistoryScreen(state);
      case 2:
        return _buildGiftsScreen(state);
      case 3:
        return _buildProfileScreen(state);
      default:
        return _buildUserHomeScreen(state);
    }
  }

  Widget _buildAdminScreen(AuthAuthenticated state, int index) {
    dev.log('HomeScreen: Building admin screen with index: $index');
    switch (index) {
      case 0:
        dev.log('HomeScreen: Building admin dashboard');
        return _buildAdminDashboard(state);
      case 1:
        dev.log('HomeScreen: Building users management');
        return _buildUsersManagement(state);
      case 2:
        dev.log('HomeScreen: Building QR codes management');
        return _buildQRCodesManagement(state);
      case 3:
        dev.log('HomeScreen: Building settings screen');
        return _buildSettingsScreen(state);
      default:
        dev.log('HomeScreen: Building default admin dashboard');
        return _buildAdminDashboard(state);
    }
  }

  // User Screens
  Widget _buildUserHomeScreen(AuthAuthenticated state) {
    final userData = state.userData;
    final points = userData['points'] as int? ?? 0;
    final level = userData['level'] as String? ?? 'مبتدئ';

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          AppText.title(
            'مرحباً ${userData['name'] ?? 'بك'}',
            color: AppColors.deepTeal,
          ),
          SizedBox(height: AppDimensions.small),
          AppText('نتمنى لك يوم سعيد', color: AppColors.lightText),
          SizedBox(height: AppDimensions.large),

          // Points card
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LevelsScreen()),
              );
            },
            child: AppContainer(
              backgroundColor: AppColors.deepTeal,
              padding: EdgeInsets.all(AppDimensions.large),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText('نقاطك الحالية', color: AppColors.white),
                      Row(
                        children: [
                          AppText('المستوى: $level', color: AppColors.white),
                          SizedBox(width: AppDimensions.tiny),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: AppColors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: AppDimensions.medium),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: AppColors.goldAccent, size: 30),
                      SizedBox(width: AppDimensions.small),
                      AppText.title(
                        '$points',
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppDimensions.large),

          // Available branches
          AppText.subtitle('الفروع المتاحة', color: AppColors.deepTeal),
          SizedBox(height: AppDimensions.medium),

          // Branches from enum
          ...Branch.values.map((branch) => Padding(
            padding: EdgeInsets.only(bottom: AppDimensions.small),
            child: AppContainer(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.lightTeal,
                  child: Icon(Icons.location_on, color: AppColors.deepTeal),
                ),
                title: AppText(branch.name, fontWeight: FontWeight.bold),
                subtitle: AppText('فرع رقم ${branch.id}', isSmall: true),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.deepTeal,
                ),
                onTap: () {
                  // Navigate to QR scanner for this branch
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const QRScannerScreen(),
                    ),
                  );
                },
              ),
            ),
          )).toList(),

          SizedBox(height: AppDimensions.medium),

          // Recent scans section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.subtitle('آخر عمليات المسح', color: AppColors.deepTeal),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ScanHistoryScreen(),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      'عرض الكل',
                      color: AppColors.deepTeal,
                      fontWeight: FontWeight.bold,
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.deepTeal,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.small),

          // Recent scans from Supabase
          BlocBuilder<UserScanHistoryCubit, ScanHistoryState>(
            builder: (context, scanState) {
              if (scanState is ScanHistoryLoading) {
                return AppContainer(
                  child: SizedBox(
                    height: 80,
                    child: Center(child: AppLoadingIndicator()),
                  ),
                );
              }
              
              if (scanState is ScanHistoryError) {
                return AppContainer(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.alertRed.withOpacity(0.1),
                      child: Icon(Icons.error, color: AppColors.alertRed),
                    ),
                    title: AppText('خطأ في تحميل سجل المسح', fontWeight: FontWeight.bold),
                    subtitle: AppText('تعذر تحميل عمليات المسح الحديثة', isSmall: true),
                  ),
                );
              }
              
              if (scanState is ScanHistoryLoaded) {
                final recentScans = scanState.scanHistory.take(3).toList(); // Show only recent 3
                
                if (recentScans.isEmpty) {
                  return AppContainer(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.lightTeal,
                        child: Icon(Icons.qr_code, color: AppColors.deepTeal),
                      ),
                      title: AppText('لا توجد عمليات مسح حديثة', fontWeight: FontWeight.bold),
                      subtitle: AppText('ابدأ بمسح رمز QR لكسب النقاط', isSmall: true),
                    ),
                  );
                }
                
                return Column(
                  children: recentScans.map((scan) {
                    final pointsEarned = scan['points_earned'] ?? 0;
                    final branch = scan['branch'] ?? 'غير محدد';
                    final scanDate = DateTime.tryParse(scan['scan_date'] ?? '') ?? DateTime.now();
                    final timeAgo = _getTimeAgo(scanDate);
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.small),
                      child: AppContainer(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.successGreen.withOpacity(0.1),
                            child: Icon(Icons.qr_code_scanner, color: AppColors.successGreen),
                          ),
                          title: AppText(
                            '+$pointsEarned نقطة من $branch',
                            fontWeight: FontWeight.bold,
                          ),
                          subtitle: AppText(timeAgo, isSmall: true),
                          trailing: Icon(
                            Icons.check_circle,
                            color: AppColors.successGreen,
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }
              
              // Default state
              return AppContainer(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.lightTeal,
                    child: Icon(Icons.qr_code, color: AppColors.deepTeal),
                  ),
                  title: AppText('لا توجد عمليات مسح حديثة', fontWeight: FontWeight.bold),
                  subtitle: AppText('ابدأ بمسح رمز QR لكسب النقاط', isSmall: true),
                ),
              );
            },
          ),

          SizedBox(height: AppDimensions.large),

          // Available gifts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.subtitle('الهدايا المتاحة', color: AppColors.deepTeal),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const GiftsScreen()),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      'عرض الكل',
                      color: AppColors.deepTeal,
                      fontWeight: FontWeight.bold,
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.deepTeal,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.medium),

          // Gifts from Supabase
          BlocBuilder<GiftCubit, GiftState>(
            builder: (context, giftState) {
              if (giftState is GiftLoading) {
                return SizedBox(
                  height: 190,
                  child: Center(child: AppLoadingIndicator()),
                );
              }
              
              if (giftState is GiftError) {
                return SizedBox(
                  height: 190,
                  child: Center(
                    child: AppText(
                      'خطأ في تحميل الهدايا',
                      color: AppColors.alertRed,
                    ),
                  ),
                );
              }
              
              if (giftState is GiftLoaded) {
                final gifts = giftState.gifts.take(3).toList(); // Show only first 3
                
                if (gifts.isEmpty) {
                  return SizedBox(
                    height: 190,
                    child: Center(
                      child: AppText(
                        'لا توجد هدايا متاحة حالياً',
                        color: AppColors.lightText,
                      ),
                    ),
                  );
                }
                
                return SizedBox(
                  height: 190,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: gifts.length,
                    itemBuilder: (context, index) {
                      final gift = gifts[index];
                      final giftName = gift['name'] as String? ?? 'هدية ${index + 1}';
                      final giftPoints = gift['points'] as int? ?? 0;
                      final imageUrl = gift['image_url'] as String?; // Fixed field name
                      final stock = gift['stock'] as int? ?? 0;
                      final isOutOfStock = stock <= 0;
                      
                      return Opacity(
                        opacity: isOutOfStock ? 0.4 : 1.0,
                        child: Container(
                          width: 150,
                          margin: EdgeInsets.only(right: AppDimensions.medium),
                          child: AppContainer(
                          padding: EdgeInsets.all(AppDimensions.small),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 70,
                                decoration: BoxDecoration(
                                  color: AppColors.lightTeal,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.small,
                                  ),
                                ),
                                child: imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          AppDimensions.small,
                                        ),
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (context, error, stackTrace) => Center(
                                            child: Icon(
                                              Icons.card_giftcard,
                                              color: AppColors.deepTeal,
                                              size: 36,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Icon(
                                          Icons.card_giftcard,
                                          color: AppColors.deepTeal,
                                          size: 36,
                                        ),
                                      ),
                              ),
                              SizedBox(height: AppDimensions.small),
                              AppText(
                                giftName,
                                fontWeight: FontWeight.bold,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: AppDimensions.tiny),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: AppColors.goldAccent,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: AppText(
                                      '$giftPoints نقطة',
                                      isSmall: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ),
                      );
                    },
                  ),
                );
              }
              
              // Default loading state
              return SizedBox(
                height: 190,
                child: Center(child: AppLoadingIndicator()),
              );
            },
          ),

          SizedBox(height: AppDimensions.large),

          // Levels section
          AppText.subtitle('المستويات', color: AppColors.deepTeal),
          SizedBox(height: AppDimensions.medium),

          // Level card
          AppContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: AppColors.goldAccent,
                          size: 24,
                        ),
                        SizedBox(width: AppDimensions.small),
                        AppText.medium(
                          'مستواك الحالي: $level',
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LevelsScreen(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText(
                            'عرض المستويات',
                            color: AppColors.deepTeal,
                            fontWeight: FontWeight.bold,
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppColors.deepTeal,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppDimensions.small),
                AppText(
                  'اكتسب المزيد من النقاط للوصول إلى المستويات الأعلى والحصول على مضاعفات أكبر للنقاط',
                  isSmall: true,
                ),
              ],
            ),
          ),

          SizedBox(height: AppDimensions.large),

          // Available offers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.subtitle('العروض المتاحة', color: AppColors.deepTeal),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const OffersScreen()),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      'عرض الكل',
                      color: AppColors.deepTeal,
                      fontWeight: FontWeight.bold,
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.deepTeal,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.medium),

          // Offers from Supabase
          BlocBuilder<OffersCubit, OffersState>(
            builder: (context, offersState) {
              if (offersState is OffersLoading) {
                return SizedBox(
                  height: 190,
                  child: Center(child: AppLoadingIndicator()),
                );
              }
              
              if (offersState is OffersError) {
                return SizedBox(
                  height: 190,
                  child: Center(
                    child: AppText(
                      'خطأ في تحميل العروض',
                      color: AppColors.alertRed,
                    ),
                  ),
                );
              }
              
              if (offersState is OffersLoaded) {
                dev.log('🏠 HomeScreen: OffersLoaded state received with ${offersState.offers.length} offers');
                for (var offer in offersState.offers) {
                  dev.log('   🎁 Home Offer: ${offer.title} (ID: ${offer.id}) - isActive: ${offer.isActive}, endDate: ${offer.endDate}');
                }
                
                final offers = offersState.offers.take(3).toList(); // Show only first 3
                dev.log('🏠 HomeScreen: Displaying first ${offers.length} offers in home screen');
                
                if (offers.isEmpty) {
                  return SizedBox(
                    height: 190,
                    child: Center(
                      child: AppText(
                        'لا توجد عروض متاحة حالياً',
                        color: AppColors.lightText,
                      ),
                    ),
                  );
                }
                
                return SizedBox(
                  height: 190,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: offers.length,
                    itemBuilder: (context, index) {
                      final offer = offers[index];
                      
                      return Container(
                        width: 150,
                        margin: EdgeInsets.only(right: AppDimensions.medium),
                        child: AppContainer(
                          padding: EdgeInsets.all(AppDimensions.small),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 70,
                                decoration: BoxDecoration(
                                  color: AppColors.lightTeal,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.small,
                                  ),
                                ),
                                child: offer.imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          AppDimensions.small,
                                        ),
                                        child: Image.network(
                                          offer.imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (context, error, stackTrace) => Center(
                                            child: Icon(
                                              Icons.local_offer,
                                              color: AppColors.deepTeal,
                                              size: 36,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Icon(
                                          Icons.local_offer,
                                          color: AppColors.deepTeal,
                                          size: 36,
                                        ),
                                      ),
                              ),
                              SizedBox(height: AppDimensions.small),
                              AppText(
                                offer.title,
                                fontWeight: FontWeight.bold,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: AppDimensions.tiny),
                              Flexible(
                                child: AppText(
                                  offer.description,
                                  isSmall: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              
              // Default loading state
              return SizedBox(
                height: 190,
                child: Center(child: AppLoadingIndicator()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScanHistoryScreen(AuthAuthenticated state) {
    return const ScanHistoryScreen();
  }

  Widget _buildGiftsScreen(AuthAuthenticated state) {
    return const GiftsScreen();
  }

  Widget _buildProfileScreen(AuthAuthenticated state) {
    return const ProfileScreen();
  }

  // Admin Screens
  Widget _buildAdminDashboard(AuthAuthenticated state) {
    try {
      return const AdminDashboardScreen();
    } catch (e) {
      dev.log('HomeScreen: Error creating admin dashboard: $e');
      return Center(child: Text('Error loading dashboard: $e'));
    }
  }

  Widget _buildUsersManagement(AuthAuthenticated state) {
    return const UsersScreen();
  }

  Widget _buildQRCodesManagement(AuthAuthenticated state) {
    return const QrCodesScreen();
  }

  Widget _buildSettingsScreen(AuthAuthenticated state) {
    dev.log('HomeScreen: Building settings screen (ProfileScreen)');
    return const ProfileScreen();
  }
}
