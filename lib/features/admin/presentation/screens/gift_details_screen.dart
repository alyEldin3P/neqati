import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_loading_indicator.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/core/utils/app_colors.dart';
import 'package:neqati/core/utils/app_dimensions.dart';
import 'package:neqati/features/admin/cubit/admin_cubit.dart';
import 'package:neqati/features/gifts/model/gift.dart';

class GiftDetailsScreen extends StatefulWidget {
  final String giftId;
  
  const GiftDetailsScreen({
    Key? key,
    required this.giftId,
  }) : super(key: key);

  @override
  State<GiftDetailsScreen> createState() => _GiftDetailsScreenState();
}

class _GiftDetailsScreenState extends State<GiftDetailsScreen> {
  Gift? _gift;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _giftRequests = [];

  @override
  void initState() {
    super.initState();
    _loadGiftDetails();
  }

  Future<void> _loadGiftDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load gift details
      final giftDoc = await context.read<AdminCubit>().getGiftById(widget.giftId);
      
      if (giftDoc == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'لم يتم العثور على الهدية';
        });
        return;
      }
      
      // Create Gift object
      _gift = Gift(
        id: giftDoc['id'] as String,
        name: giftDoc['name'] as String? ?? '',
        points: giftDoc['points'] as int? ?? 0,
        stock: giftDoc['stock'] as int? ?? 0,
        imageUrl: giftDoc['imageUrl'] as String?,
        createdAt: giftDoc['createdAt'] != null 
          ? (giftDoc['createdAt'] as dynamic).toDate() 
          : null,
      );
      
      // Load gift requests
      _giftRequests = await context.read<AdminCubit>().getGiftRequests(widget.giftId);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ أثناء تحميل بيانات الهدية: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.deepTeal,
        title: AppText(
          _gift?.name ?? 'تفاصيل الهدية',
          color: AppColors.white,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        actions: [
          if (_gift != null)
            IconButton(
              icon: Icon(Icons.edit, color: AppColors.white),
              onPressed: () => _showEditGiftForm(),
              tooltip: 'تعديل الهدية',
            ),
        ],
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.alertRed, size: 48),
            const SizedBox(height: AppDimensions.medium),
            AppText(
              _errorMessage!,
              color: AppColors.alertRed,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.large),
            ElevatedButton(
              onPressed: _loadGiftDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepTeal,
              ),
              child: AppText('إعادة المحاولة', color: AppColors.white),
            ),
          ],
        ),
      );
    }

    if (_gift == null) {
      return Center(
        child: AppText('لم يتم العثور على بيانات الهدية'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGiftDetails,
      color: AppColors.deepTeal,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gift image and details
            AppContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_gift!.imageUrl != null && _gift!.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimensions.small),
                      child: Image.network(
                        _gift!.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          width: double.infinity,
                          color: AppColors.lightTeal,
                          child: Icon(
                            Icons.card_giftcard,
                            color: AppColors.deepTeal,
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.medium),
                  ],
                  
                  AppText(
                    _gift!.name,
                    fontWeight: FontWeight.bold,
                    // Use a larger text style instead of fontSize
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: AppDimensions.small),
                  
                  _buildInfoRow(
                    icon: Icons.star,
                    iconColor: AppColors.goldAccent,
                    label: 'النقاط المطلوبة',
                    value: '${_gift!.points} نقطة',
                  ),
                  
                  _buildInfoRow(
                    icon: Icons.inventory_2_outlined,
                    iconColor: AppColors.deepTeal,
                    label: 'المخزون المتاح',
                    value: '${_gift!.stock} قطعة',
                  ),
                  
                  if (_gift!.createdAt != null)
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      iconColor: AppColors.lightText,
                      label: 'تاريخ الإضافة',
                      value: '${_gift!.createdAt!.day}/${_gift!.createdAt!.month}/${_gift!.createdAt!.year}',
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: AppDimensions.large),
            
            // Gift requests section
            AppText(
              'طلبات الهدية',
              fontWeight: FontWeight.bold,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: AppDimensions.small),
            
            if (_giftRequests.isEmpty)
              AppContainer(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.medium),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.lightText,
                          size: 32,
                        ),
                        const SizedBox(height: AppDimensions.small),
                        AppText(
                          'لا توجد طلبات لهذه الهدية حتى الآن',
                          color: AppColors.lightText,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _giftRequests.length,
                itemBuilder: (context, index) {
                  final request = _giftRequests[index];
                  final userName = request['userName'] as String? ?? 'مستخدم';
                  final userPhone = request['userPhone'] as String? ?? '-';
                  final requestDate = request['requestDate'] != null
                      ? (request['requestDate'] as dynamic).toDate()
                      : null;
                  final status = request['status'] as String? ?? 'pending';
                  
                  return AppContainer(
                    margin: const EdgeInsets.only(bottom: AppDimensions.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.lightTeal,
                              child: Icon(
                                Icons.person,
                                color: AppColors.deepTeal,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.medium),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    userName,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  AppText(
                                    userPhone,
                                    isSmall: true,
                                    color: AppColors.lightText,
                                  ),
                                ],
                              ),
                            ),
                            _buildStatusChip(status),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.small),
                        const Divider(),
                        const SizedBox(height: AppDimensions.small),
                        if (requestDate != null)
                          AppText(
                            'تاريخ الطلب: ${requestDate.day}/${requestDate.month}/${requestDate.year}',
                            isSmall: true,
                            color: AppColors.lightText,
                          ),
                        const SizedBox(height: AppDimensions.small),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (status == 'pending') ...[
                              TextButton(
                                onPressed: () => _updateRequestStatus(request['id'] as String, 'rejected'),
                                child: AppText(
                                  'رفض',
                                  color: AppColors.alertRed,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.small),
                              ElevatedButton(
                                onPressed: () => _updateRequestStatus(request['id'] as String, 'approved'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.deepTeal,
                                ),
                                child: AppText(
                                  'قبول',
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.small),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: AppDimensions.small),
          AppText(label, color: AppColors.lightText),
          const SizedBox(width: AppDimensions.small),
          AppText(value, fontWeight: FontWeight.bold),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    String statusText;
    
    switch (status) {
      case 'approved':
        chipColor = Colors.green;
        statusText = 'تم القبول';
        break;
      case 'rejected':
        chipColor = AppColors.alertRed;
        statusText = 'مرفوض';
        break;
      case 'pending':
      default:
        chipColor = Colors.orange;
        statusText = 'قيد الانتظار';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.small,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppDimensions.tiny),
        border: Border.all(color: chipColor),
      ),
      child: AppText(
        statusText,
        isSmall: true,
        color: chipColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _showEditGiftForm() {
    if (_gift == null) return;
    
    final nameController = TextEditingController(text: _gift!.name);
    final pointsController = TextEditingController(text: _gift!.points.toString());
    final stockController = TextEditingController(text: _gift!.stock.toString());
    final imageUrlController = TextEditingController(text: _gift!.imageUrl ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText('تعديل الهدية', fontWeight: FontWeight.bold),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'اسم الهدية',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppDimensions.medium),
              TextField(
                controller: pointsController,
                decoration: InputDecoration(
                  labelText: 'النقاط المطلوبة',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppDimensions.medium),
              TextField(
                controller: stockController,
                decoration: InputDecoration(
                  labelText: 'المخزون المتاح',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppDimensions.medium),
              TextField(
                controller: imageUrlController,
                decoration: InputDecoration(
                  labelText: 'رابط الصورة',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_gift?.imageUrl != null && _gift!.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.medium),
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.lightText),
                    borderRadius: BorderRadius.circular(AppDimensions.tiny),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.tiny),
                    child: Image.network(
                      _gift!.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(Icons.error, color: AppColors.alertRed),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: AppText('إلغاء', color: AppColors.lightText),
          ),
          ElevatedButton(
            onPressed: () {
              // Validate inputs
              final name = nameController.text.trim();
              final pointsText = pointsController.text.trim();
              final stockText = stockController.text.trim();
              final imageUrl = imageUrlController.text.trim();
              
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: AppText('يرجى إدخال اسم الهدية', color: AppColors.white)),
                );
                return;
              }
              
              int? points;
              int? stock;
              
              try {
                points = int.parse(pointsText);
                if (points < 0) throw FormatException('Points must be positive');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: AppText('يرجى إدخال قيمة صحيحة للنقاط', color: AppColors.white)),
                );
                return;
              }
              
              try {
                stock = int.parse(stockText);
                if (stock < 0) throw FormatException('Stock must be positive');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: AppText('يرجى إدخال قيمة صحيحة للمخزون', color: AppColors.white)),
                );
                return;
              }
              
              Navigator.pop(context);
              
              // Update gift
              context.read<AdminCubit>().updateGift(
                giftId: _gift!.id,
                giftData: {
                  'name': name,
                  'points': points,
                  'stock': stock,
                  'imageUrl': imageUrl.isEmpty ? null : imageUrl,
                },
              ).then((_) {
                // Reload gift details
                _loadGiftDetails();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepTeal,
            ),
            child: AppText('تحديث', color: AppColors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _updateRequestStatus(String requestId, String status) async {
    try {
      await context.read<AdminCubit>().updateGiftRequestStatus(requestId, status);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText(
            status == 'approved' ? 'تم قبول الطلب بنجاح' : 'تم رفض الطلب',
            color: AppColors.white,
          ),
          backgroundColor: status == 'approved' ? Colors.green : AppColors.alertRed,
        ),
      );
      
      // Reload gift details
      _loadGiftDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AppText('حدث خطأ: ${e.toString()}', color: AppColors.white),
          backgroundColor: AppColors.alertRed,
        ),
      );
    }
  }
}
