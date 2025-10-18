import 'package:flutter/material.dart';
import 'package:neqati/core/const/branches.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_loading.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/core/services/scan_service.dart';
import 'package:neqati/core/utils/app_colors.dart';
import 'package:neqati/core/utils/app_dimensions.dart';
import 'package:neqati/features/auth/model/user.dart';

class UserScanHistoryScreen extends StatefulWidget {
  final AppUser user;

  const UserScanHistoryScreen({super.key, required this.user});

  @override
  State<UserScanHistoryScreen> createState() => _UserScanHistoryScreenState();
}

class _UserScanHistoryScreenState extends State<UserScanHistoryScreen> {
  final ScanService _scanService = ScanService();
  List<Map<String, dynamic>> _allScans = [];
  List<Map<String, dynamic>> _filteredScans = [];
  bool _isLoading = true;
  String? _selectedBranch;

  @override
  void initState() {
    super.initState();
    _loadScanHistory();
  }

  Future<void> _loadScanHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final scans = await _scanService.getUserScanHistory(widget.user.id);
      
      if (mounted) {
        setState(() {
          _allScans = scans;
          _filteredScans = scans;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
        );
      }
    }
  }

  void _filterByBranch(String? branch) {
    setState(() {
      _selectedBranch = branch;
      if (branch == null) {
        _filteredScans = _allScans;
      } else {
        _filteredScans = _allScans.where((scan) => scan['branch'] == branch).toList();
      }
    });
  }

  int _getTotalPoints() {
    return _filteredScans.fold<int>(
      0,
      (sum, scan) => sum + (scan['points_earned'] as int? ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.title('سجل المسح - ${widget.user.name}', color: AppColors.white),
        backgroundColor: AppColors.deepTeal,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(AppDimensions.medium),
            color: AppColors.softWhite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.subtitle('تصفية حسب الفرع', color: AppColors.deepTeal),
                const SizedBox(height: AppDimensions.small),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.medium),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.lightText.withValues(alpha: 0.3)),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedBranch,
                          isExpanded: true,
                          underline: const SizedBox(),
                          hint: AppText('جميع الفروع'),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('جميع الفروع'),
                            ),
                            ...Branch.values.map((branch) {
                              return DropdownMenuItem<String>(
                                value: branch.name,
                                child: Text(branch.name),
                              );
                            }),
                          ],
                          onChanged: _filterByBranch,
                        ),
                      ),
                    ),
                    if (_selectedBranch != null) ...[
                      const SizedBox(width: AppDimensions.small),
                      IconButton(
                        onPressed: () => _filterByBranch(null),
                        icon: const Icon(Icons.clear, color: AppColors.deepTeal),
                        tooltip: 'إزالة التصفية',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppDimensions.small),
                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      'عدد المسحات: ${_filteredScans.length}',
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepTeal,
                    ),
                    AppText(
                      'إجمالي النقاط: ${_getTotalPoints()}',
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepTeal,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scan History List
          Expanded(
            child: _isLoading
                ? const Center(child: AppLoading())
                : _filteredScans.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 64,
                              color: AppColors.lightText.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: AppDimensions.medium),
                            AppText(
                              _selectedBranch != null
                                  ? 'لا توجد مسحات لهذا الفرع'
                                  : 'لا يوجد سجل مسح',
                              color: AppColors.lightText,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadScanHistory,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppDimensions.medium),
                          itemCount: _filteredScans.length,
                          itemBuilder: (context, index) {
                            final scan = _filteredScans[index];
                            final scanDate = DateTime.parse(scan['scan_date']);
                            final branch = scan['branch'] as String?;
                            final points = scan['points_earned'] as int? ?? 0;

                            return AppContainer(
                              margin: const EdgeInsets.only(bottom: AppDimensions.small),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(AppDimensions.small),
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.deepTeal,
                                  child: const Icon(
                                    Icons.qr_code_scanner,
                                    color: AppColors.white,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    AppText(
                                      'النقاط: $points',
                                      fontWeight: FontWeight.bold,
                                    ),
                                    const Spacer(),
                                    if (branch != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.deepTeal.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: AppText(
                                          branch,
                                          isSmall: true,
                                          color: AppColors.deepTeal,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: AppColors.lightText,
                                        ),
                                        const SizedBox(width: 4),
                                        AppText(
                                          '${scanDate.day}/${scanDate.month}/${scanDate.year}',
                                          isSmall: true,
                                          color: AppColors.lightText,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: AppColors.lightText,
                                        ),
                                        const SizedBox(width: 4),
                                        AppText(
                                          '${scanDate.hour}:${scanDate.minute.toString().padLeft(2, '0')}',
                                          isSmall: true,
                                          color: AppColors.lightText,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
