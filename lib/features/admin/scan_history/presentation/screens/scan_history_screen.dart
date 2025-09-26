import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_loading.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/core/utils/app_colors.dart';
import 'package:neqati/core/utils/app_dimensions.dart';
import 'package:neqati/features/admin/scan_history/cubit/scan_history_cubit.dart';
import 'package:neqati/features/admin/scan_history/cubit/scan_history_state.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _scans = [];
  bool _hasMore = false;
  int _currentOffset = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadScans();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreScans();
    }
  }

  void _loadScans() {
    setState(() {
      _currentOffset = 0;
      _scans.clear();
    });
    context.read<ScanHistoryCubit>().loadScans();
  }

  void _loadMoreScans() {
    if (_hasMore && !_isLoading) {
      setState(() {
        _isLoading = true;
        _currentOffset += 20;
      });
      context.read<ScanHistoryCubit>().loadScans(offset: _currentOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.title('سجل المسح', color: AppColors.white),
        backgroundColor: AppColors.deepTeal,
        centerTitle: true,
      ),
      body: BlocConsumer<ScanHistoryCubit, ScanHistoryState>(
        listener: (context, state) {
          if (state is ScansLoaded) {
            setState(() {
              if (_currentOffset == 0) {
                _scans = state.scans;
              } else {
                _scans.addAll(state.scans);
              }
              _hasMore = state.hasMore;
              _isLoading = false;
            });
          } else if (state is ScanHistoryError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            setState(() {
              _isLoading = false;
            });
          }
        },
        builder: (context, state) {
          if (state is ScanHistoryLoading && _scans.isEmpty) {
            return const Center(child: AppLoading());
          }

          if (_scans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText('لا يوجد سجل مسح'),
                  const SizedBox(height: AppDimensions.medium),
                  ElevatedButton(
                    onPressed: _loadScans,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepTeal,
                    ),
                    child: AppText('إعادة المحاولة', color: AppColors.white),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppDimensions.medium),
            itemCount: _scans.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _scans.length) {
                return const Center(child: AppLoading());
              }

              final scan = _scans[index];
              return _buildScanCard(scan);
            },
          );
        },
      ),
    );
  }

  Widget _buildScanCard(Map<String, dynamic> scan) {
    final scanDate = DateTime.parse(scan['scan_date']);
    final user = scan['users'] as Map<String, dynamic>?;

    return AppContainer(
      margin: const EdgeInsets.only(bottom: AppDimensions.small),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.small),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.deepTeal,
              child: Icon(Icons.qr_code_scanner, color: AppColors.white),
            ),
            const SizedBox(width: AppDimensions.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    user?['name'] ?? 'مستخدم غير معروف',
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    'النقاط المكتسبة: ${scan['points_earned']}',
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    'الفرع: ${scan['branch'] ?? 'غير محدد'}',
                    isSmall: true,
                    color: AppColors.lightText,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    '${scanDate.day}/${scanDate.month}/${scanDate.year} - ${scanDate.hour}:${scanDate.minute.toString().padLeft(2, '0')}',
                    isSmall: true,
                    color: AppColors.lightText,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: AppText(
                    '+${scan['points_earned']}',
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    isSmall: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
