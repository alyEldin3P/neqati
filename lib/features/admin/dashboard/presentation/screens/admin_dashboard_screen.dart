import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/presentation/widgets/app_loading.dart';
import 'package:neqati/features/admin/gift_management/presentation/screens/admin_gift_requests_screen.dart';
import 'package:neqati/features/admin/gift_management/presentation/screens/gifts_screen.dart';
import 'package:neqati/features/admin/level_management/presentation/screens/admin_levels_screen.dart';
import 'package:neqati/features/admin/offer_management/presentation/screens/offers_screen.dart';
import 'package:neqati/features/admin/qr_management/presentation/screens/qr_code_creation_screen.dart';
import 'package:neqati/features/admin/qr_management/presentation/screens/qr_codes_screen.dart';
import 'package:neqati/features/admin/scan_history/presentation/screens/scan_history_screen.dart';
import 'package:neqati/features/admin/user_management/presentation/screens/pending_users_screen.dart';
import 'package:neqati/features/admin/user_management/presentation/screens/users_screen.dart';
import 'package:neqati/features/offers/presentation/screens/offers_screen.dart';
import '../../../../../core/presentation/widgets/app_text.dart';
import '../../../../../core/presentation/widgets/app_container.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_dimensions.dart';
import '../../cubit/dashboard_cubit.dart';
import '../../cubit/dashboard_state.dart';
import '../widgets/stats_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadAdminStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<DashboardCubit, DashboardState>(
        listener: (context, state) {
          if (state is DashboardError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: AppLoading());
          }

          if (state is DashboardStatsLoaded) {
            return _buildDashboard(context, state);
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText('حدث خطأ في تحميل البيانات'),
                const SizedBox(height: AppDimensions.medium),
                ElevatedButton(
                  onPressed:
                      () => context.read<DashboardCubit>().loadAdminStats(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepTeal,
                  ),
                  child: AppText('إعادة المحاولة', color: AppColors.white),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardStatsLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.title('إحصائيات عامة', color: AppColors.deepTeal),
          const SizedBox(height: AppDimensions.medium),

          // Stats cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppDimensions.small,
            crossAxisSpacing: AppDimensions.small,
            childAspectRatio: 1.5,
            children: [
              StatsCard(
                title: 'المستخدمين',
                value: state.stats.totalUsers.toString(),
                icon: Icons.people,
                color: AppColors.deepTeal,
                onTap: () => _navigateTo(context, const UsersScreen()),
              ),
              StatsCard(
                title: 'طلبات التسجيل',
                value: state.stats.totalPendingUsers.toString(),
                icon: Icons.person_add,
                color: Colors.orange,
                onTap: () => _navigateTo(context, const PendingUsersScreen()),
              ),
              StatsCard(
                title: 'عمليات المسح',
                value: state.stats.totalScans.toString(),
                icon: Icons.qr_code_scanner,
                color: Colors.purple,
                onTap: () => _navigateTo(context, const ScanHistoryScreen()),
              ),
              StatsCard(
                title: 'رموز QR',
                value: state.stats.totalQrCodes.toString(),
                icon: Icons.qr_code,
                color: Colors.blue,
                onTap: () => _navigateTo(context, const QrCodesScreen()),
              ),
              StatsCard(
                title: 'الهدايا',
                value: state.stats.totalGifts.toString(),
                icon: Icons.card_giftcard,
                color: Colors.red,
                onTap: () => _navigateTo(context, const GiftsScreen()),
              ),
              StatsCard(
                title: 'العروض',
                value: state.stats.totalOffers.toString(),
                icon: Icons.local_offer,
                color: Colors.green,
                onTap: () => _navigateTo(context, const OffersScreen()),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.large),
          AppText.title('الإدارة السريعة', color: AppColors.deepTeal),
          const SizedBox(height: AppDimensions.medium),

          // Quick actions
          AppContainer(
            child: Column(
              children: [
                _buildQuickAction(
                  context,
                  'إدارة المستخدمين',
                  Icons.people,
                  () => _navigateTo(context, const UsersScreen()),
                ),
                const Divider(),
                _buildQuickAction(
                  context,
                  'طلبات التسجيل الجديدة',
                  Icons.person_add,
                  () => _navigateTo(context, const PendingUsersScreen()),
                ),
                const Divider(),
                _buildQuickAction(
                  context,
                  'إنشاء رمز QR جديد',
                  Icons.qr_code,
                  () => _navigateTo(context, const QRCodeCreationScreen()),
                ),
                const Divider(),
                _buildQuickAction(
                  context,
                  'إدارة الهدايا',
                  Icons.card_giftcard,
                  () => _navigateTo(context, const GiftsScreen()),
                ),
                const Divider(),
                _buildQuickAction(
                  context,
                  'إدارة العروض',
                  Icons.local_offer,
                  () => _navigateTo(context, const OffersManagementScreen()),
                ),
                const Divider(),
                _buildQuickAction(
                  context,
                  'إدارة المستويات',
                  Icons.emoji_events,
                  () => _navigateTo(context, const AdminLevelsScreen()),
                ),
                const Divider(),
                _buildQuickAction(
                  context,
                  'طلبات الهدايا',
                  Icons.card_giftcard_outlined,
                  () => _navigateTo(context, const AdminGiftRequestsScreen()),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.large),
          AppText.title('طلبات الهدايا المعلقة', color: AppColors.deepTeal),
          const SizedBox(height: AppDimensions.medium),

          // Pending gift requests
          AppContainer(
            child:
                state.stats.totalPendingGiftRequests > 0
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'لديك ${state.stats.totalPendingGiftRequests} طلب هدية معلق',
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: AppDimensions.small),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const AdminGiftRequestsScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.deepTeal,
                          ),
                          child: AppText('عرض الطلبات', color: AppColors.white),
                        ),
                      ],
                    )
                    : Center(child: AppText('لا توجد طلبات هدايا معلقة')),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.small),
        child: Row(
          children: [
            Icon(icon, color: AppColors.deepTeal),
            const SizedBox(width: AppDimensions.medium),
            AppText(title, fontWeight: FontWeight.bold),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}
