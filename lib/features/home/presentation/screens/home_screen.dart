import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/widgets/app_text.dart';
import '../../../../core/presentation/widgets/app_container.dart';
import '../../../../core/presentation/widgets/app_loading_indicator.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dimensions.dart';
import '../../../auth/cubit/auth_cubit.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../gifts/presentation/screens/gifts_screen.dart';
import '../../../gifts/presentation/screens/qr_scanner_screen.dart';
import '../../../gifts/presentation/screens/scan_history_screen.dart';
import '../../../levels/presentation/screens/levels_screen.dart';
import '../../../offers/presentation/screens/offers_screen.dart';
import '../widgets/app_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  final bool isAdmin;
  
  const HomeScreen({
    Key? key,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softWhite,
      appBar: AppBar(
        backgroundColor: AppColors.deepTeal,
        elevation: 0,
        title: AppText(
          widget.isAdmin ? 'لوحة التحكم' : 'نقاطي',
          color: AppColors.white,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.white),
            onPressed: () {
              // TODO: Navigate to notifications screen
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return _buildBody(state);
          } else {
            return const Center(child: AppLoadingIndicator());
          }
        },
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        isAdmin: widget.isAdmin,
      ),
      floatingActionButton: _currentIndex == 1 && !widget.isAdmin
          ? FloatingActionButton(
              backgroundColor: AppColors.deepTeal,
              child: const Icon(Icons.qr_code_scanner, color: AppColors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const QRScannerScreen(),
                  ),
                );
              },
            )
          : null,
    );
  }

  Widget _buildBody(AuthAuthenticated state) {
    // For now, we'll just show different screens based on the navigation index
    // Later, we'll implement proper navigation with separate screens
    
    if (widget.isAdmin) {
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
    switch (index) {
      case 0:
        return _buildAdminDashboard(state);
      case 1:
        return _buildUsersManagement(state);
      case 2:
        return _buildQRCodesManagement(state);
      case 3:
        return _buildSettingsScreen(state);
      default:
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
          AppText(
            'نتمنى لك يوم سعيد',
            color: AppColors.lightText,
          ),
          SizedBox(height: AppDimensions.large),
          
          // Points card
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LevelsScreen(),
                ),
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
                      AppText(
                        'نقاطك الحالية',
                        color: AppColors.white,
                      ),
                      Row(
                        children: [
                          AppText(
                            'المستوى: $level',
                            color: AppColors.white,
                          ),
                          SizedBox(width: AppDimensions.tiny),
                          Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.white),
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
          
          // Recent scans
          AppText.subtitle(
            'آخر عمليات المسح',
            color: AppColors.deepTeal,
          ),
          SizedBox(height: AppDimensions.medium),
          
          // Placeholder for recent scans
          AppContainer(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.lightTeal,
                child: Icon(Icons.qr_code, color: AppColors.deepTeal),
              ),
              title: AppText('فرع الرياض', fontWeight: FontWeight.bold),
              subtitle: AppText('تم إضافة 50 نقطة', isSmall: true),
              trailing: AppText('اليوم', isCaption: true),
            ),
          ),
          SizedBox(height: AppDimensions.small),
          
          // Placeholder for more scans
          AppContainer(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.lightTeal,
                child: Icon(Icons.qr_code, color: AppColors.deepTeal),
              ),
              title: AppText('فرع جدة', fontWeight: FontWeight.bold),
              subtitle: AppText('تم إضافة 30 نقطة', isSmall: true),
              trailing: AppText('أمس', isCaption: true),
            ),
          ),
          SizedBox(height: AppDimensions.medium),
          
          // View all button
          Center(
            child: TextButton(
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
                  Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.deepTeal),
                ],
              ),
            ),
          ),
          
          SizedBox(height: AppDimensions.large),
          
          // Available gifts
          AppText.subtitle(
            'الهدايا المتاحة',
            color: AppColors.deepTeal,
          ),
          SizedBox(height: AppDimensions.medium),
          
          // Horizontal list of gifts
          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3, // Placeholder count
              itemBuilder: (context, index) {
                return Container(
                  width: 150,
                  margin: EdgeInsets.only(right: AppDimensions.medium),
                  child: AppContainer(
                    padding: EdgeInsets.all(AppDimensions.small),
                    child: LayoutBuilder(builder: (context, constraints) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 70,
                            decoration: BoxDecoration(
                              color: AppColors.lightTeal,
                              borderRadius: BorderRadius.circular(AppDimensions.small),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.card_giftcard,
                                color: AppColors.deepTeal,
                                size: 36,
                              ),
                            ),
                          ),
                          SizedBox(height: AppDimensions.small),
                          AppText(
                            'هدية ${index + 1}',
                            fontWeight: FontWeight.bold,
                          ),
                          SizedBox(height: AppDimensions.tiny),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: AppColors.goldAccent, size: 14),
                              SizedBox(width: 4),
                              Flexible(
                                child: AppText(
                                  '${(index + 1) * 100} نقطة',
                                  isSmall: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                  ),
                );
              },
            ),
          ),
          
          // View all gifts button
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GiftsScreen(),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    'عرض كل الهدايا',
                    color: AppColors.deepTeal,
                    fontWeight: FontWeight.bold,
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.deepTeal),
                ],
              ),
            ),
          ),
          
          SizedBox(height: AppDimensions.large),
          
          // Levels section
          AppText.subtitle(
            'المستويات',
            color: AppColors.deepTeal,
          ),
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
                        Icon(Icons.emoji_events, color: AppColors.goldAccent),
                        SizedBox(width: AppDimensions.small),
                        AppText.subtitle(
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
                          Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.deepTeal),
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
          AppText.subtitle(
            'العروض المتاحة',
            color: AppColors.deepTeal,
          ),
          SizedBox(height: AppDimensions.medium),
          
          // Horizontal list of offers
          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3, // Placeholder count
              itemBuilder: (context, index) {
                return Container(
                  width: 150,
                  margin: EdgeInsets.only(right: AppDimensions.medium),
                  child: AppContainer(
                    padding: EdgeInsets.all(AppDimensions.small),
                    child: LayoutBuilder(builder: (context, constraints) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 70,
                            decoration: BoxDecoration(
                              color: AppColors.lightTeal,
                              borderRadius: BorderRadius.circular(AppDimensions.small),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.local_offer,
                                color: AppColors.deepTeal,
                                size: 36,
                              ),
                            ),
                          ),
                          SizedBox(height: AppDimensions.small),
                          AppText(
                            'عرض ${index + 1}',
                            fontWeight: FontWeight.bold,
                          ),
                          SizedBox(height: AppDimensions.tiny),
                          Flexible(
                            child: AppText(
                              'عرض خاص لفترة محدودة',
                              isSmall: true,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                );
              },
            ),
          ),
          
          // View all offers button
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const OffersScreen(),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    'عرض كل العروض',
                    color: AppColors.deepTeal,
                    fontWeight: FontWeight.bold,
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.deepTeal),
                ],
              ),
            ),
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
    return Center(
      child: AppText('لوحة التحكم', color: AppColors.deepTeal),
    );
  }

  Widget _buildUsersManagement(AuthAuthenticated state) {
    return Center(
      child: AppText('إدارة المستخدمين', color: AppColors.deepTeal),
    );
  }

  Widget _buildQRCodesManagement(AuthAuthenticated state) {
    return Center(
      child: AppText('إدارة رموز QR', color: AppColors.deepTeal),
    );
  }

  Widget _buildSettingsScreen(AuthAuthenticated state) {
    return Center(
      child: AppText('الإعدادات', color: AppColors.deepTeal),
    );
  }
}
