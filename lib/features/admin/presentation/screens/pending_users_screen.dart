import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_loading.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/core/utils/app_colors.dart';
import 'package:neqati/core/utils/app_dimensions.dart';
import 'package:neqati/features/admin/cubit/admin_cubit.dart';
import 'package:neqati/features/admin/cubit/admin_state.dart';
import 'package:neqati/features/admin/presentation/screens/user_details_screen.dart';
import 'package:neqati/features/auth/model/user.dart';

class PendingUsersScreen extends StatefulWidget {
  const PendingUsersScreen({Key? key}) : super(key: key);

  @override
  State<PendingUsersScreen> createState() => _PendingUsersScreenState();
}

class _PendingUsersScreenState extends State<PendingUsersScreen> {
  @override
  void initState() {
    super.initState();
    _loadPendingUsers();
  }

  void _loadPendingUsers() {
    context.read<AdminCubit>().loadPendingUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.title('طلبات التسجيل', color: AppColors.white),
        backgroundColor: AppColors.deepTeal,
        centerTitle: true,
      ),
      body: BlocConsumer<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state is UserActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            _loadPendingUsers();
          } else if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: AppLoading());
          }

          if (state is PendingUsersLoaded) {
            final pendingUsers = state.pendingUsers;

            if (pendingUsers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppText('لا توجد طلبات تسجيل معلقة'),
                    const SizedBox(height: AppDimensions.medium),
                    ElevatedButton(
                      onPressed: _loadPendingUsers,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepTeal,
                      ),
                      child: AppText('تحديث', color: AppColors.white),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _loadPendingUsers();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(AppDimensions.medium),
                itemCount: pendingUsers.length,
                itemBuilder: (context, index) {
                  final user = pendingUsers[index];
                  return _buildPendingUserCard(context, user);
                },
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText('حدث خطأ أثناء تحميل طلبات التسجيل'),
                const SizedBox(height: AppDimensions.medium),
                ElevatedButton(
                  onPressed: _loadPendingUsers,
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

  Widget _buildPendingUserCard(BuildContext context, AppUser user) {
    return AppContainer(
      margin: const EdgeInsets.only(bottom: AppDimensions.small),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.small),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.deepTeal,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: AppDimensions.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        user.name ?? 'مستخدم',
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        user.phoneNumber ?? '-',
                        isSmall: true,
                        color: AppColors.lightText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: AppDimensions.large),
            _buildInfoRow('البريد الإلكتروني', user.email ?? '-'),
            _buildInfoRow('النقاط', user.points.toString()),
            _buildInfoRow('المستوى', user.level),
            const SizedBox(height: AppDimensions.small),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserDetailsScreen(userId: user.id),
                      ),
                    ).then((_) => _loadPendingUsers());
                  },
                  child: AppText(
                    'عرض التفاصيل',
                    color: AppColors.deepTeal,
                  ),
                ),
                const SizedBox(width: AppDimensions.small),
                ElevatedButton(
                  onPressed: () {
                    _showVerifyUserDialog(context, user);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: AppText(
                    'قبول',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppDimensions.small),
                ElevatedButton(
                  onPressed: () {
                    _showRejectUserDialog(context, user);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: AppText(
                    'رفض',
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: AppText(
              '$label:',
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: AppText(value),
          ),
        ],
      ),
    );
  }

  void _showVerifyUserDialog(BuildContext context, AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText('تفعيل المستخدم'),
        content: AppText('هل أنت متأكد من تفعيل المستخدم ${user.name ?? 'مستخدم'}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: AppText('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminCubit>().verifyUser(user.id);
            },
            child: AppText(
              'تأكيد',
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectUserDialog(BuildContext context, AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText('رفض المستخدم'),
        content: AppText('هل أنت متأكد من رفض المستخدم ${user.name ?? 'مستخدم'}؟ سيتم حذف بيانات المستخدم.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: AppText('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectUser(user.id);
            },
            child: AppText(
              'تأكيد',
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectUser(String userId) async {
    try {
      // Delete the user document
      await context.read<AdminCubit>().deleteUser(userId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفض المستخدم بنجاح')),
      );
      
      _loadPendingUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
    }
  }
}
