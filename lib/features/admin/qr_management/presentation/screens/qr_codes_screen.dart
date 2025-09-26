import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/features/admin/qr_management/cubit/qr_management_cubit.dart';
import 'package:neqati/features/admin/qr_management/cubit/qr_management_state.dart';
import 'package:neqati/features/admin/qr_management/presentation/screens/qr_code_creation_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodesScreen extends StatefulWidget {
  const QrCodesScreen({Key? key}) : super(key: key);

  @override
  State<QrCodesScreen> createState() => _QrCodesScreenState();
}

class _QrCodesScreenState extends State<QrCodesScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentOffset = 0;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> _qrCodes = [];
  int _totalQrCodes = 0;
  String _filterStatus = 'all'; // 'all', 'used', 'unused'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadQrCodes();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_qrCodes.length < _totalQrCodes && !_isLoadingMore) {
        _loadMoreQrCodes();
      }
    }
  }

  void _loadQrCodes({String? query}) {
    setState(() {
      _currentOffset = 0;
      _qrCodes.clear();
    });
    context.read<QrManagementCubit>().loadQRCodes(searchQuery: query);
  }

  void _loadMoreQrCodes() {
    if (!_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
        _currentOffset += 10;
      });
      String? searchQuery =
          _searchController.text.isNotEmpty ? _searchController.text : null;
      context.read<QrManagementCubit>().loadQRCodes(
        offset: _currentOffset,
        searchQuery: searchQuery,
      );
    }
  }

  void _refreshQrCodes() {
    setState(() {
      _qrCodes = [];
      _currentOffset = 0;
    });
    _loadQrCodes();
  }

  void _filterQrCodes(String status) {
    setState(() {
      _filterStatus = status;
      _qrCodes = [];
      _currentOffset = 0;
    });
    _loadQrCodes();
  }

  void _searchQrCodes(String query) {
    setState(() {
      _qrCodes = [];
      _currentOffset = 0;
    });
    _loadQrCodes(query: query);
  }

  void _deleteQrCode(String qrCodeId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const AppText('تأكيد الحذف', fontWeight: FontWeight.bold),
            content: const AppText('هل أنت متأكد من حذف رمز QR هذا؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const AppText('إلغاء', color: Colors.grey),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<QrManagementCubit>().deleteQRCode(qrCodeId);
                },
                child: const AppText('حذف', color: Colors.red),
              ),
            ],
          ),
    );
  }

  void _showQrCodeDetails(Map<String, dynamic> qrCode) {
    // Create QR data for display
    final qrData = 'QR_${qrCode['id']}:${qrCode['points']}:${qrCode['branch']}';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const AppText('تفاصيل رمز QR', fontWeight: FontWeight.bold),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200,
                    ),
                    const SizedBox(height: 20),
                    _detailRow('المعرف:', qrCode['id']?.toString() ?? ''),
                    _detailRow('النقاط:', '${qrCode['points'] ?? 0}'),
                    _detailRow('الفرع:', qrCode['branch'] ?? ''),
                    _detailRow(
                      'الحالة:',
                      qrCode['status'] == 'scanned' ? 'مستخدم' : 'غير مستخدم',
                    ),
                    _detailRow(
                      'تاريخ الإنشاء:',
                      _formatDate(qrCode['creation_date']),
                    ),
                    _detailRow(
                      'مدة الانتهاء:',
                      '${qrCode['expiry_duration'] ?? 0} يوم',
                    ),
                    if (qrCode['status'] == 'scanned') ...[
                      _detailRow('مستخدم بواسطة:', qrCode['scanned_by_name'] ?? qrCode['scanned_by'] ?? ''),
                      _detailRow(
                        'تاريخ الاستخدام:',
                        _formatDate(qrCode['scan_date']),
                      ),
                    ],
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: qrData));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ بيانات QR إلى الحافظة'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const AppText(
                          'نسخ بيانات QR',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const AppText('إغلاق'),
              ),
            ],
          ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(child: AppText(label, fontWeight: FontWeight.bold)),
          Expanded(flex: 3, child: AppText(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'غير متوفر';

    try {
      if (date is String) {
        final dateTime = DateTime.parse(date);
        return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
      } else if (date is DateTime) {
        return DateFormat('yyyy-MM-dd HH:mm').format(date);
      }
      return 'غير متوفر';
    } catch (e) {
      return 'غير متوفر';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText(
          'إدارة رموز QR',
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QRCodeCreationScreen(),
            ),
          ).then((_) => _refreshQrCodes());
        },
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<QrManagementCubit, QrManagementState>(
        listener: (context, state) {
          if (state is QrCodesLoaded) {
            setState(() {
              if (_currentOffset == 0) {
                _qrCodes = List<Map<String, dynamic>>.from(state.qrCodes);
              } else {
                _qrCodes.addAll(List<Map<String, dynamic>>.from(state.qrCodes));
              }

              _totalQrCodes = state.totalQrCodes;
              _isLoadingMore = false;
            });
          } else if (state is QrCodeDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم حذف رمز QR بنجاح')),
            );
            _refreshQrCodes();
          } else if (state is QrManagementError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            setState(() {
              _isLoadingMore = false;
            });
          }
        },
        builder: (context, state) {
          if (state is QrManagementLoading && _qrCodes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'بحث عن رمز QR...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchQrCodes('');
                          },
                        ),
                      ),
                      onSubmitted: _searchQrCodes,
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('الكل', 'all'),
                          const SizedBox(width: 10),
                          _filterChip('مستخدم', 'used'),
                          const SizedBox(width: 10),
                          _filterChip('غير مستخدم', 'unused'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    _qrCodes.isEmpty
                        ? const Center(child: AppText('لا توجد رموز QR'))
                        : ListView.builder(
                          controller: _scrollController,
                          itemCount: _qrCodes.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _qrCodes.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final qrCode = _qrCodes[index];
                            return AppContainer(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                title: AppText(
                                  'رمز QR #${index + 1}',
                                  fontWeight: FontWeight.bold,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText('النقاط: ${qrCode['points']}'),
                                    AppText('الفرع: ${qrCode['branch']}'),
                                    AppText(
                                      'الحالة: ${qrCode['status'] == 'scanned' ? 'مستخدم' : 'غير مستخدم'}',
                                      color:
                                          qrCode['status'] == 'scanned'
                                              ? Colors.red
                                              : Colors.green,
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.qr_code,
                                        color: Colors.blue,
                                      ),
                                      onPressed:
                                          () => _showQrCodeDetails(qrCode),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => _deleteQrCode(
                                            qrCode['id']?.toString() ?? '',
                                          ),
                                    ),
                                  ],
                                ),
                                onTap: () => _showQrCodeDetails(qrCode),
                              ),
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: AppText(label, color: isSelected ? Colors.white : Colors.black),
      selected: isSelected,
      onSelected: (_) => _filterQrCodes(value),
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor,
    );
  }
}
