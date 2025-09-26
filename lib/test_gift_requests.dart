import 'package:flutter/material.dart';
import 'core/services/gift_service.dart';
import 'core/services/dependency_injector.dart';
import 'core/presentation/widgets/app_text.dart';
import 'core/utils/app_colors.dart';
import 'core/utils/app_dimensions.dart';
import 'dart:developer' as developer;

/// Simple test screen to verify gift request functionality
class TestGiftRequestsScreen extends StatefulWidget {
  const TestGiftRequestsScreen({super.key});

  @override
  State<TestGiftRequestsScreen> createState() => _TestGiftRequestsScreenState();
}

class _TestGiftRequestsScreenState extends State<TestGiftRequestsScreen> {
  final GiftService _giftService = DependencyInjector().giftService;
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _allRequests = [];
  bool _isLoading = false;
  String _status = 'Ready to test';

  Future<void> _testPendingRequests() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing pending gift requests...';
    });

    try {
      developer.log('🧪 TestGiftRequests: Testing getAllPendingGiftRequests()');
      final requests = await _giftService.getAllPendingGiftRequests();
      
      setState(() {
        _pendingRequests = requests;
        _status = 'Found ${requests.length} pending requests';
        _isLoading = false;
      });

      developer.log('🧪 TestGiftRequests: Success - ${requests.length} pending requests');
      if (requests.isNotEmpty) {
        developer.log('🧪 TestGiftRequests: First request: ${requests[0]}');
      }
    } catch (e) {
      developer.log('❌ TestGiftRequests: Error testing pending requests: $e');
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testAllRequests() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing all gift requests...';
    });

    try {
      developer.log('🧪 TestGiftRequests: Testing getAllGiftRequests()');
      final requests = await _giftService.getAllGiftRequests();
      
      setState(() {
        _allRequests = requests;
        _status = 'Found ${requests.length} total requests';
        _isLoading = false;
      });

      developer.log('🧪 TestGiftRequests: Success - ${requests.length} total requests');
      if (requests.isNotEmpty) {
        developer.log('🧪 TestGiftRequests: First request: ${requests[0]}');
      }
    } catch (e) {
      developer.log('❌ TestGiftRequests: Error testing all requests: $e');
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText('Test Gift Requests'),
        backgroundColor: AppColors.deepTeal,
      ),
      body: Padding(
        padding: EdgeInsets.all(AppDimensions.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Container(
              padding: EdgeInsets.all(AppDimensions.medium),
              decoration: BoxDecoration(
                color: AppColors.lightTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.small),
                border: Border.all(color: AppColors.lightTeal),
              ),
              child: AppText(
                'Status: $_status',
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: AppDimensions.large),
            
            // Test buttons
            ElevatedButton(
              onPressed: _isLoading ? null : _testPendingRequests,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepTeal,
                padding: EdgeInsets.all(AppDimensions.medium),
              ),
              child: AppText(
                'Test Pending Requests (${_pendingRequests.length})',
                color: AppColors.white,
              ),
            ),
            
            SizedBox(height: AppDimensions.medium),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testAllRequests,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightTeal,
                padding: EdgeInsets.all(AppDimensions.medium),
              ),
              child: AppText(
                'Test All Requests (${_allRequests.length})',
                color: AppColors.white,
              ),
            ),
            
            SizedBox(height: AppDimensions.large),
            
            // Results
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(color: AppColors.deepTeal),
              )
            else if (_pendingRequests.isNotEmpty || _allRequests.isNotEmpty) ...[
              AppText(
                'Results:',
                fontWeight: FontWeight.bold,
                color: AppColors.deepTeal,
              ),
              SizedBox(height: AppDimensions.medium),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_pendingRequests.isNotEmpty) ...[
                        AppText(
                          'Pending Requests (${_pendingRequests.length}):',
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: AppDimensions.small),
                        ..._pendingRequests.map((request) => Container(
                          margin: EdgeInsets.only(bottom: AppDimensions.small),
                          padding: EdgeInsets.all(AppDimensions.small),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(AppDimensions.tiny),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: AppText(
                            'ID: ${request['id']}\nUser: ${request['users']?['name'] ?? 'Unknown'}\nGift: ${request['gifts']?['name'] ?? 'Unknown'}\nStatus: ${request['status']}',
                            isSmall: true,
                          ),
                        )),
                        SizedBox(height: AppDimensions.medium),
                      ],
                      
                      if (_allRequests.isNotEmpty) ...[
                        AppText(
                          'All Requests (${_allRequests.length}):',
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: AppDimensions.small),
                        ..._allRequests.take(5).map((request) => Container(
                          margin: EdgeInsets.only(bottom: AppDimensions.small),
                          padding: EdgeInsets.all(AppDimensions.small),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(AppDimensions.tiny),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: AppText(
                            'ID: ${request['id']}\nUser: ${request['users']?['name'] ?? 'Unknown'}\nGift: ${request['gifts']?['name'] ?? 'Unknown'}\nStatus: ${request['status']}',
                            isSmall: true,
                          ),
                        )),
                        if (_allRequests.length > 5)
                          AppText(
                            '... and ${_allRequests.length - 5} more',
                            isSmall: true,
                            color: AppColors.lightText,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
