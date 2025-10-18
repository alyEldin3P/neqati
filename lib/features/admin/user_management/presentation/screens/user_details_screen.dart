import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_loading.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/core/services/scan_service.dart';
import 'package:neqati/core/services/user_service.dart';
import 'package:neqati/core/utils/app_colors.dart';
import 'package:neqati/core/utils/app_dimensions.dart';
import 'package:neqati/features/admin/user_management/cubit/user_management_cubit.dart';
import 'package:neqati/features/admin/gift_management/cubit/gift_request_management_cubit.dart';
import 'package:neqati/features/admin/gift_management/cubit/gift_request_management_state.dart';
import 'package:neqati/features/admin/gift_management/model/gift_request.dart';
import 'package:neqati/features/auth/model/user.dart';
import 'package:neqati/features/admin/user_management/presentation/screens/user_scan_history_screen.dart';

class UserDetailsScreen extends StatefulWidget {
  final String userId;

  const UserDetailsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  AppUser? _user;
  bool _isLoading = true;
  List<Map<String, dynamic>> _scanHistory = [];
  final TextEditingController _pointsController = TextEditingController();
  late UserService _userService;
  late ScanService _scanService;

  @override
  void initState() {
    super.initState();
    _userService = UserService();
    _scanService = ScanService();
    _loadUserData();
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Load user data
      final userData = await _userService.getUserData(widget.userId);

      if (userData != null && mounted) {
        setState(() {
          _user = AppUser.fromSupabase(userData, userData['id']);
        });
      }

      // Load scan history
      final scanHistory = await _scanService.getUserScanHistory(widget.userId);
      if (mounted) {
        setState(() {
          _scanHistory = scanHistory.take(10).toList();
        });
      }

      // Load gift requests using the cubit
      if (mounted) {
        context.read<GiftRequestManagementCubit>().loadUserGiftRequests(widget.userId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.title('تفاصيل المستخدم', color: AppColors.white),
        backgroundColor: AppColors.deepTeal,
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: AppLoading())
              : _user == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppText('لم يتم العثور على المستخدم'),
                    const SizedBox(height: AppDimensions.medium),
                    ElevatedButton(
                      onPressed: _loadUserData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepTeal,
                      ),
                      child: AppText('إعادة المحاولة', color: AppColors.white),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserInfoCard(),
                    const SizedBox(height: AppDimensions.medium),
                    _buildActionsCard(),
                    const SizedBox(height: AppDimensions.medium),
                    _buildScanHistoryCard(),
                    const SizedBox(height: AppDimensions.medium),
                    _buildGiftRequestsCard(),
                  ],
                ),
              ),
    );
  }

  Widget _buildUserInfoCard() {
    return AppContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.deepTeal,
                radius: 30,
                child: Icon(
                  _user!.isAdmin ? Icons.admin_panel_settings : Icons.person,
                  color: AppColors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppDimensions.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.title(_user!.name ?? 'مستخدم'),
                    AppText(
                      _user!.phoneNumber ?? '-',
                      color: AppColors.lightText,
                    ),
                    AppText(_user!.email ?? '-', color: AppColors.lightText),
                    Row(
                      children: [
                        if (_user!.isAdmin)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: AppText(
                              'مدير',
                              color: Colors.white,
                              isSmall: true,
                            ),
                          ),
                        if (_user!.isBlocked)
                          Container(
                            margin: const EdgeInsets.only(top: 4, right: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: AppText(
                              'محظور',
                              color: Colors.white,
                              isSmall: true,
                            ),
                          ),
                        if (!_user!.isVerified)
                          Container(
                            margin: const EdgeInsets.only(top: 4, right: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: AppText(
                              'غير مفعل',
                              color: Colors.white,
                              isSmall: true,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppDimensions.large),
          // User details
          _buildInfoRow('البريد الإلكتروني', _user!.email ?? '-'),
          _buildInfoRow('النقاط', _user!.points.toString()),
          _buildInfoRow('المستوى', _user!.level),
        ],
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
            child: AppText('$label:', fontWeight: FontWeight.bold),
          ),
          Expanded(child: AppText(value)),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return AppContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.subtitle('الإجراءات', color: AppColors.deepTeal),
          const SizedBox(height: AppDimensions.small),

          // Block/Unblock user
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _user!.isBlocked ? Icons.lock_open : Icons.lock,
              color: _user!.isBlocked ? Colors.green : Colors.red,
            ),
            title: AppText(
              _user!.isBlocked ? 'إلغاء حظر المستخدم' : 'حظر المستخدم',
            ),
            onTap: () {
              _showBlockUserDialog();
            },
          ),

          // Verify user if not verified
          if (!_user!.isVerified)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: AppText('تفعيل المستخدم'),
              onTap: () {
                _showVerifyUserDialog();
              },
            ),

          // Update points
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.add_circle, color: Colors.blue),
            title: AppText('تعديل النقاط'),
            onTap: () {
              _showUpdatePointsDialog();
            },
          ),

          // Toggle admin status
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _user!.isAdmin ? Icons.remove_moderator : Icons.admin_panel_settings,
              color: _user!.isAdmin ? Colors.orange : Colors.purple,
            ),
            title: AppText(_user!.isAdmin ? 'إلغاء صلاحيات المدير' : 'ترقية إلى مدير'),
            onTap: () {
              _showToggleAdminDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScanHistoryCard() {
    return AppContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.subtitle('سجل المسح', color: AppColors.deepTeal),
          const SizedBox(height: AppDimensions.small),

          if (_scanHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.medium),
                child: AppText('لا يوجد سجل مسح'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _scanHistory.length,
              itemBuilder: (context, index) {
                final scan = _scanHistory[index];
                final scanDate = DateTime.parse(scan['scan_date']);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.deepTeal,
                    child: Icon(Icons.qr_code_scanner, color: Colors.white),
                  ),
                  title: AppText('النقاط: ${scan['points_earned']}'),
                  subtitle: AppText(
                    'الفرع: ${scan['branch']} - ${scanDate.day}/${scanDate.month}/${scanDate.year}',
                    isSmall: true,
                    color: AppColors.lightText,
                  ),
                );
              },
            ),

          if (_scanHistory.isNotEmpty)
            TextButton(
              onPressed: () {
                if (_user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserScanHistoryScreen(user: _user!),
                    ),
                  );
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    'عرض المزيد',
                    color: AppColors.deepTeal,
                    fontWeight: FontWeight.bold,
                  ),
                  const Icon(Icons.arrow_forward, color: AppColors.deepTeal),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGiftRequestsCard() {
    return AppContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.subtitle('طلبات الهدايا', color: AppColors.deepTeal),
          const SizedBox(height: AppDimensions.small),

          BlocConsumer<GiftRequestManagementCubit, GiftRequestManagementState>(
            listener: (context, state) {
              if (state is GiftRequestActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
                // Reload user gift requests after action
                context.read<GiftRequestManagementCubit>().loadUserGiftRequests(widget.userId);
              } else if (state is UserGiftRequestsError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
            builder: (context, state) {
              if (state is UserGiftRequestsLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppDimensions.medium),
                    child: AppLoading(),
                  ),
                );
              }

              if (state is UserGiftRequestsError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.medium),
                    child: Column(
                      children: [
                        AppText('خطأ في تحميل طلبات الهدايا'),
                        const SizedBox(height: AppDimensions.small),
                        ElevatedButton(
                          onPressed: () {
                            context.read<GiftRequestManagementCubit>().loadUserGiftRequests(widget.userId);
                          },
                          child: AppText('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is UserGiftRequestsLoaded) {
                final giftRequests = state.giftRequests;
                
                if (giftRequests.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.medium),
                      child: AppText('لا يوجد طلبات هدايا'),
                    ),
                  );
                }

                return Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: giftRequests.take(5).length, // Show first 5
                      itemBuilder: (context, index) {
                        final request = giftRequests[index];
                        
                        Color statusColor;
                        switch (request.status) {
                          case 'pending':
                            statusColor = Colors.orange;
                            break;
                          case 'approved':
                            statusColor = Colors.green;
                            break;
                          case 'rejected':
                            statusColor = Colors.red;
                            break;
                          default:
                            statusColor = Colors.grey;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: AppDimensions.small),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.deepTeal,
                              child: Icon(Icons.card_giftcard, color: Colors.white),
                            ),
                            title: AppText(request.giftName ?? 'هدية غير معروفة'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  'النقاط: ${request.giftPoints ?? 0}',
                                  isSmall: true,
                                  color: AppColors.lightText,
                                ),
                                AppText(
                                  '${request.requestDate.day}/${request.requestDate.month}/${request.requestDate.year}',
                                  isSmall: true,
                                  color: AppColors.lightText,
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: AppText(
                                    request.statusDisplayName,
                                    color: Colors.white,
                                    isSmall: true,
                                  ),
                                ),
                              ],
                            ),
                            trailing: request.isPending
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check,
                                          color: Colors.green,
                                        ),
                                        onPressed: () {
                                          _showApproveDialog(request);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          _showRejectDialog(request);
                                        },
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                    if (giftRequests.length > 5)
                      TextButton(
                        onPressed: () {
                          // Navigate to full gift requests screen
                          _showAllGiftRequestsDialog(giftRequests);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppText(
                              'عرض جميع الطلبات (${giftRequests.length})',
                              color: AppColors.deepTeal,
                              fontWeight: FontWeight.bold,
                            ),
                            const Icon(Icons.arrow_forward, color: AppColors.deepTeal),
                          ],
                        ),
                      ),
                  ],
                );
              }

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.medium),
                  child: AppText('لا يوجد طلبات هدايا'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }


  void _showBlockUserDialog() {
    final isBlocked = _user!.isBlocked;
    final action = isBlocked ? 'إلغاء حظر' : 'حظر';
    final message =
        isBlocked
            ? 'هل أنت متأكد من إلغاء حظر المستخدم ${_user!.name}؟'
            : 'هل أنت متأكد من حظر المستخدم ${_user!.name}؟';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: AppText('$action المستخدم'),
            content: AppText(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: AppText('إلغاء'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await context.read<UserManagementCubit>().blockUser(
                      _user!.id,
                      !isBlocked,
                    );
                    await _loadUserData(); // Refetch user data after successful action
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isBlocked
                                ? 'تم إلغاء حظر المستخدم بنجاح'
                                : 'تم حظر المستخدم بنجاح',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
                      );
                    }
                  }
                },
                child: AppText(
                  'تأكيد',
                  color: isBlocked ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
    );
  }

  void _showVerifyUserDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: AppText('تفعيل المستخدم'),
            content: AppText('هل أنت متأكد من تفعيل المستخدم ${_user!.name}؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: AppText('إلغاء'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await context.read<UserManagementCubit>().verifyUser(
                      _user!.id,
                    );
                    await _loadUserData(); // Refetch user data after successful action
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تفعيل المستخدم بنجاح'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
                      );
                    }
                  }
                },
                child: AppText('تأكيد', color: Colors.green),
              ),
            ],
          ),
    );
  }

  void _showUpdatePointsDialog() {
    _pointsController.text = '';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: AppText('تعديل النقاط'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText('النقاط الحالية: ${_user!.points}'),
                const SizedBox(height: AppDimensions.small),
                TextField(
                  controller: _pointsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'النقاط المراد إضافتها/خصمها',
                    hintText: 'أدخل رقم موجب للإضافة أو سالب للخصم',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: AppText('إلغاء'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final pointsText = _pointsController.text.trim();
                  if (pointsText.isNotEmpty) {
                    final points = int.tryParse(pointsText);
                    if (points != null) {
                      try {
                        await context
                            .read<UserManagementCubit>()
                            .updateUserPoints(_user!.id, points);
                        await _loadUserData(); // Refetch user data after successful action
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تحديث النقاط بنجاح'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
                          );
                        }
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('الرجاء إدخال رقم صحيح'),
                          ),
                        );
                      }
                    }
                  }
                },
                child: AppText('تأكيد', color: AppColors.deepTeal),
              ),
            ],
          ),
    );
  }

  void _showToggleAdminDialog() {
    final isAdmin = _user!.isAdmin;
    final action = isAdmin ? 'إلغاء صلاحيات المدير' : 'ترقية إلى مدير';
    final message =
        isAdmin
            ? 'هل أنت متأكد من إلغاء صلاحيات المدير لـ ${_user!.name}؟'
            : 'هل أنت متأكد من ترقية ${_user!.name} إلى مدير؟';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: AppText(action),
            content: AppText(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: AppText('إلغاء'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await context.read<UserManagementCubit>().toggleAdminStatus(
                      _user!.id,
                      !isAdmin,
                    );
                    await _loadUserData(); // Refetch user data after successful action
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isAdmin
                                ? 'تم إلغاء صلاحيات المدير بنجاح'
                                : 'تمت الترقية إلى مدير بنجاح',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
                      );
                    }
                  }
                },
                child: AppText(
                  'تأكيد',
                  color: isAdmin ? Colors.orange : Colors.purple,
                ),
              ),
            ],
          ),
    );
  }

  void _showApproveDialog(GiftRequest request) {
    final TextEditingController notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText('قبول طلب الهدية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText('هل أنت متأكد من قبول طلب الهدية؟'),
            const SizedBox(height: AppDimensions.small),
            AppText('الهدية: ${request.giftName}', fontWeight: FontWeight.bold),
            AppText('النقاط المطلوبة: ${request.giftPoints}', fontWeight: FontWeight.bold),
            AppText('المستخدم: ${request.userName}', fontWeight: FontWeight.bold),
            const SizedBox(height: AppDimensions.medium),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات إضافية (اختياري)',
                hintText: 'أدخل أي ملاحظات للمستخدم',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: AppText('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<GiftRequestManagementCubit>().approveGiftRequest(
                request.id,
                adminNotes: notesController.text.trim(),
              );
            },
            child: AppText('قبول', color: Colors.green),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(GiftRequest request) {
    final TextEditingController notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText('رفض طلب الهدية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText('هل أنت متأكد من رفض طلب الهدية؟'),
            const SizedBox(height: AppDimensions.small),
            AppText('الهدية: ${request.giftName}', fontWeight: FontWeight.bold),
            AppText('النقاط المطلوبة: ${request.giftPoints}', fontWeight: FontWeight.bold),
            AppText('المستخدم: ${request.userName}', fontWeight: FontWeight.bold),
            const SizedBox(height: AppDimensions.medium),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'سبب الرفض (اختياري)',
                hintText: 'أدخل سبب رفض الطلب',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: AppText('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<GiftRequestManagementCubit>().rejectGiftRequest(
                request.id,
                adminNotes: notesController.text.trim(),
              );
            },
            child: AppText('رفض', color: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showAllGiftRequestsDialog(List<GiftRequest> giftRequests) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(AppDimensions.medium),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.title('جميع طلبات الهدايا'),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: giftRequests.length,
                  itemBuilder: (context, index) {
                    final request = giftRequests[index];
                    
                    Color statusColor;
                    switch (request.status) {
                      case 'pending':
                        statusColor = Colors.orange;
                        break;
                      case 'approved':
                        statusColor = Colors.green;
                        break;
                      case 'rejected':
                        statusColor = Colors.red;
                        break;
                      default:
                        statusColor = Colors.grey;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppDimensions.small),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.deepTeal,
                          child: Icon(Icons.card_giftcard, color: Colors.white),
                        ),
                        title: AppText(request.giftName ?? 'هدية غير معروفة'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              'النقاط: ${request.giftPoints ?? 0}',
                              isSmall: true,
                              color: AppColors.lightText,
                            ),
                            AppText(
                              '${request.requestDate.day}/${request.requestDate.month}/${request.requestDate.year}',
                              isSmall: true,
                              color: AppColors.lightText,
                            ),
                            if (request.adminNotes != null && request.adminNotes!.isNotEmpty)
                              AppText(
                                'ملاحظات: ${request.adminNotes}',
                                isSmall: true,
                                color: AppColors.lightText,
                              ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: AppText(
                                request.statusDisplayName,
                                color: Colors.white,
                                isSmall: true,
                              ),
                            ),
                          ],
                        ),
                        trailing: request.isPending
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showApproveDialog(request);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showRejectDialog(request);
                                    },
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
