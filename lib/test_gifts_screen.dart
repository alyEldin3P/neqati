import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'debug_gifts.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/gifts/cubit/gift_cubit.dart';
import 'features/gifts/cubit/gift_state.dart';
import 'core/presentation/widgets/app_text.dart';
import 'core/utils/app_colors.dart';
import 'core/utils/app_dimensions.dart';

/// Temporary test screen to debug gift functionality
class TestGiftsScreen extends StatefulWidget {
  const TestGiftsScreen({super.key});

  @override
  State<TestGiftsScreen> createState() => _TestGiftsScreenState();
}

class _TestGiftsScreenState extends State<TestGiftsScreen> {
  String _debugOutput = '';

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  void _runTests() async {
    setState(() {
      _debugOutput = 'Starting debug tests...\n';
    });

    // Test 1: Check gifts table
    await DebugGifts.testGiftsTable();
    
    // Test 2: Check user data
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      await DebugGifts.testUserData(authState.user.id);
    }
    
    // Test 3: Load gifts through cubit
    if (authState is AuthAuthenticated) {
      context.read<GiftCubit>().loadGifts(authState.user.id);
    }
    
    setState(() {
      _debugOutput += 'Debug tests completed. Check console logs for details.\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText('Test Gifts Debug'),
        backgroundColor: AppColors.deepTeal,
      ),
      body: Padding(
        padding: EdgeInsets.all(AppDimensions.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Gift Debug Information',
              fontWeight: FontWeight.bold,
              color: AppColors.deepTeal,
            ),
            SizedBox(height: AppDimensions.medium),
            
            // Debug output
            Container(
              padding: EdgeInsets.all(AppDimensions.small),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(AppDimensions.small),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: AppText(
                _debugOutput,
                isSmall: true,
                color: Colors.black87,
              ),
            ),
            
            SizedBox(height: AppDimensions.large),
            
            // Gift cubit state
            AppText(
              'Gift Cubit State:',
              fontWeight: FontWeight.bold,
              color: AppColors.deepTeal,
            ),
            SizedBox(height: AppDimensions.small),
            
            BlocBuilder<GiftCubit, GiftState>(
              builder: (context, state) {
                return Container(
                  padding: EdgeInsets.all(AppDimensions.small),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(AppDimensions.small),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'State Type: ${state.runtimeType}',
                        isSmall: true,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: AppDimensions.tiny),
                      
                      if (state is GiftLoading)
                        AppText('Loading gifts...', isSmall: true, color: Colors.orange),
                      
                      if (state is GiftError)
                        AppText('Error: ${state.message}', isSmall: true, color: Colors.red),
                      
                      if (state is GiftLoaded) ...[
                        AppText('User Points: ${state.userPoints}', isSmall: true),
                        AppText('Gifts Count: ${state.gifts.length}', isSmall: true),
                        if (state.gifts.isNotEmpty) ...[
                          SizedBox(height: AppDimensions.tiny),
                          AppText('First Gift:', isSmall: true, fontWeight: FontWeight.bold),
                          AppText('${state.gifts[0]}', isSmall: true),
                        ],
                      ],
                      
                      if (state is GiftRequestLoading)
                        AppText('Processing gift request...', isSmall: true, color: Colors.orange),
                      
                      if (state is GiftRequestSuccess)
                        AppText('Success: ${state.message}', isSmall: true, color: Colors.green),
                      
                      if (state is GiftRequestError)
                        AppText('Request Error: ${state.message}', isSmall: true, color: Colors.red),
                    ],
                  ),
                );
              },
            ),
            
            SizedBox(height: AppDimensions.large),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _runTests,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepTeal,
                    ),
                    child: AppText('Run Tests Again', color: AppColors.white),
                  ),
                ),
                SizedBox(width: AppDimensions.medium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final authState = context.read<AuthCubit>().state;
                      if (authState is AuthAuthenticated) {
                        context.read<GiftCubit>().loadGifts(authState.user.id);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightTeal,
                    ),
                    child: AppText('Reload Gifts', color: AppColors.white),
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
