import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_loading.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/core/utils/app_colors.dart';
import 'package:neqati/core/utils/app_dimensions.dart';
import 'package:neqati/features/admin/cubit/admin_cubit.dart';
// Removed unused import
import 'package:neqati/features/auth/model/user.dart';

class UserDetailsScreen extends StatefulWidget {
  final String userId;

  const UserDetailsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  AppUser? _user;
  bool _isLoading = true;
  List<Map<String, dynamic>> _scanHistory = [];
  List<Map<String, dynamic>> _giftRequests = [];
  final TextEditingController _pointsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          _user = AppUser.fromFirestore(userDoc.data()!, userDoc.id);
        });
      }

      // Load scan history
      final scansSnapshot = await FirebaseFirestore.instance
          .collection('scans')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('scanDate', descending: true)
          .limit(10)
          .get();

      setState(() {
        _scanHistory = scansSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
      });

      // Load gift requests
      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('requestDate', descending: true)
          .limit(10)
          .get();

      setState(() {
        _giftRequests = requestsSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      body: _isLoading
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
          
          // Make admin
          if (!_user!.isAdmin)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.admin_panel_settings, color: Colors.purple),
              title: AppText('ترقية إلى مدير'),
              onTap: () {
                _showMakeAdminDialog();
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
                final scanDate = (scan['scanDate'] as Timestamp).toDate();
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.deepTeal,
                    child: Icon(Icons.qr_code_scanner, color: Colors.white),
                  ),
                  title: AppText('النقاط: ${scan['pointsEarned']}'),
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
                // Navigate to full scan history
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
          
          if (_giftRequests.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.medium),
                child: AppText('لا يوجد طلبات هدايا'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _giftRequests.length,
              itemBuilder: (context, index) {
                final request = _giftRequests[index];
                final requestDate = (request['requestDate'] as Timestamp).toDate();
                final status = request['status'] as String;
                
                Color statusColor;
                switch (status) {
                  case 'pending':
                    statusColor = Colors.orange;
                    break;
                  case 'approved':
                    statusColor = Colors.green;
                    break;
                  case 'denied':
                    statusColor = Colors.red;
                    break;
                  default:
                    statusColor = Colors.grey;
                }
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.deepTeal,
                    child: Icon(Icons.card_giftcard, color: Colors.white),
                  ),
                  title: AppText('هدية: ${request['giftId']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        '${requestDate.day}/${requestDate.month}/${requestDate.year}',
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
                          _getStatusText(status),
                          color: Colors.white,
                          isSmall: true,
                        ),
                      ),
                    ],
                  ),
                  trailing: status == 'pending'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () {
                                _approveGiftRequest(request['id']);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                _denyGiftRequest(request['id']);
                              },
                            ),
                          ],
                        )
                      : null,
                );
              },
            ),
          
          if (_giftRequests.isNotEmpty)
            TextButton(
              onPressed: () {
                // Navigate to full gift requests history
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

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'approved':
        return 'تمت الموافقة';
      case 'denied':
        return 'تم الرفض';
      default:
        return 'غير معروف';
    }
  }

  void _showBlockUserDialog() {
    final isBlocked = _user!.isBlocked;
    final action = isBlocked ? 'إلغاء حظر' : 'حظر';
    final message = isBlocked
        ? 'هل أنت متأكد من إلغاء حظر المستخدم ${_user!.name}؟'
        : 'هل أنت متأكد من حظر المستخدم ${_user!.name}؟';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText('$action المستخدم'),
        content: AppText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: AppText('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminCubit>().blockUser(_user!.id, !isBlocked).then((_) {
                _loadUserData();
              });
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
      builder: (context) => AlertDialog(
        title: AppText('تفعيل المستخدم'),
        content: AppText('هل أنت متأكد من تفعيل المستخدم ${_user!.name}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: AppText('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminCubit>().verifyUser(_user!.id).then((_) {
                _loadUserData();
              });
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

  void _showUpdatePointsDialog() {
    _pointsController.text = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () {
              Navigator.pop(context);
              final pointsText = _pointsController.text.trim();
              if (pointsText.isNotEmpty) {
                final points = int.tryParse(pointsText);
                if (points != null) {
                  context.read<AdminCubit>().updateUserPoints(_user!.id, points).then((_) {
                    _loadUserData();
                  });
                }
              }
            },
            child: AppText(
              'تأكيد',
              color: AppColors.deepTeal,
            ),
          ),
        ],
      ),
    );
  }

  void _showMakeAdminDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText('ترقية إلى مدير'),
        content: AppText('هل أنت متأكد من ترقية ${_user!.name} إلى مدير؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: AppText('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(_user!.id)
                  .update({'isAdmin': true}).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت الترقية إلى مدير بنجاح')),
                );
                _loadUserData();
              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('حدث خطأ: ${error.toString()}')),
                );
              });
            },
            child: AppText(
              'تأكيد',
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveGiftRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({'status': 'approved'});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت الموافقة على طلب الهدية')),
      );
      
      _loadUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
    }
  }

  Future<void> _denyGiftRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({'status': 'denied'});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفض طلب الهدية')),
      );
      
      _loadUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
      );
    }
  }
}
