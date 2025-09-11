import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/features/admin/cubit/admin_cubit.dart';
import 'package:neqati/features/admin/cubit/admin_state.dart';
import 'package:neqati/features/admin/presentation/screens/qr_code_creation_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodesScreen extends StatefulWidget {
  const QrCodesScreen({Key? key}) : super(key: key);

  @override
  State<QrCodesScreen> createState() => _QrCodesScreenState();
}

class _QrCodesScreenState extends State<QrCodesScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _lastDocId;
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
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_qrCodes.length < _totalQrCodes && !_isLoadingMore) {
        _loadMoreQrCodes();
      }
    }
  }

  void _loadQrCodes({String? query}) {
    context.read<AdminCubit>().loadQRCodes(searchQuery: query);
  }

  void _loadMoreQrCodes() {
    if (_qrCodes.isNotEmpty) {
      setState(() {
        _isLoadingMore = true;
      });
      String? searchQuery = _searchController.text.isNotEmpty ? _searchController.text : null;
      context.read<AdminCubit>().loadQRCodes(lastDocId: _lastDocId, searchQuery: searchQuery);
    }
  }

  void _refreshQrCodes() {
    setState(() {
      _qrCodes = [];
      _lastDocId = null;
    });
    _loadQrCodes();
  }

  void _filterQrCodes(String status) {
    setState(() {
      _filterStatus = status;
      _qrCodes = [];
      _lastDocId = null;
    });
    _loadQrCodes();
  }

  void _searchQrCodes(String query) {
    setState(() {
      _qrCodes = [];
      _lastDocId = null;
    });
    _loadQrCodes(query: query);
  }

  void _deleteQrCode(String qrCodeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppText(
          'تأكيد الحذف',
          fontWeight: FontWeight.bold,
        ),
        content: const AppText(
          'هل أنت متأكد من حذف رمز QR هذا؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AppText(
              'إلغاء',
              color: Colors.grey,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminCubit>().deleteQRCode(qrCodeId);
            },
            child: const AppText(
              'حذف',
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _showQrCodeDetails(Map<String, dynamic> qrCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const AppText(
          'تفاصيل رمز QR',
          fontWeight: FontWeight.bold,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              QrImageView(
                data: qrCode['data'] ?? '',
                version: QrVersions.auto,
                size: 200,
              ),
              const SizedBox(height: 20),
              _detailRow('المعرف:', qrCode['id'] ?? ''),
              _detailRow('النقاط:', '${qrCode['points'] ?? 0}'),
              _detailRow('الفرع:', qrCode['branch'] ?? ''),
              _detailRow('الحالة:', qrCode['isUsed'] == true ? 'مستخدم' : 'غير مستخدم'),
              _detailRow('تاريخ الإنشاء:', _formatTimestamp(qrCode['createdAt'])),
              _detailRow('تاريخ الانتهاء:', _formatDate(qrCode['expiryDate'])),
              if (qrCode['isUsed'] == true) ...[
                _detailRow('مستخدم بواسطة:', qrCode['usedBy'] ?? ''),
                _detailRow('تاريخ الاستخدام:', _formatTimestamp(qrCode['usedAt'])),
              ],
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: qrCode['data'] ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ بيانات QR إلى الحافظة')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const AppText('نسخ بيانات QR', color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AppText(
              'إغلاق',
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            label,
            fontWeight: FontWeight.bold,
          ),
          AppText(
            value,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'غير متوفر';
    
    try {
      if (timestamp is Map && timestamp.containsKey('seconds')) {
        final seconds = timestamp['seconds'];
        final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        return DateFormat('yyyy-MM-dd HH:mm').format(date);
      }
      return 'غير متوفر';
    } catch (e) {
      return 'غير متوفر';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'غير متوفر';
    
    try {
      if (date is Map && date.containsKey('seconds')) {
        final seconds = date['seconds'];
        final dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        return DateFormat('yyyy-MM-dd').format(dateTime);
      } else if (date is DateTime) {
        return DateFormat('yyyy-MM-dd').format(date);
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
            MaterialPageRoute(builder: (context) => const QRCodeCreationScreen()),
          ).then((_) => _refreshQrCodes());
        },
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state is QrCodesLoaded) {
            setState(() {
              if (_lastDocId == null) {
                _qrCodes = List<Map<String, dynamic>>.from(state.qrCodes);
              } else {
                _qrCodes.addAll(List<Map<String, dynamic>>.from(state.qrCodes));
              }
              
              _totalQrCodes = state.totalQrCodes;
              
              if (_qrCodes.isNotEmpty) {
                _lastDocId = _qrCodes.last['id'];
              }
              
              _isLoadingMore = false;
            });
          } else if (state is QrCodeDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم حذف رمز QR بنجاح')),
            );
            _refreshQrCodes();
          } else if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            setState(() {
              _isLoadingMore = false;
            });
          }
        },
        builder: (context, state) {
          if (state is AdminLoading && _qrCodes.isEmpty) {
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
                child: _qrCodes.isEmpty
                    ? const Center(
                        child: AppText(
                          'لا توجد رموز QR',
                        ),
                      )
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
                                  AppText(
                                    'النقاط: ${qrCode['points']}',
                                  ),
                                  AppText(
                                    'الفرع: ${qrCode['branch']}',
                                  ),
                                  AppText(
                                    'الحالة: ${qrCode['isUsed'] == true ? 'مستخدم' : 'غير مستخدم'}',
                                    color: qrCode['isUsed'] == true ? Colors.red : Colors.green,
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.qr_code, color: Colors.blue),
                                    onPressed: () => _showQrCodeDetails(qrCode),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteQrCode(qrCode['id']),
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
      label: AppText(
        label,
        color: isSelected ? Colors.white : Colors.black,
      ),
      selected: isSelected,
      onSelected: (_) => _filterQrCodes(value),
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor,
    );
  }
}
