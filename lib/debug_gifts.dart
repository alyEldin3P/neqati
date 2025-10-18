import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

/// Debug utility to test gifts table and troubleshoot issues
class DebugGifts {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Test the gifts table structure and data
  static Future<void> testGiftsTable() async {
    await createSampleGift();
  }

  /// Create a sample gift for testing
  static Future<void> createSampleGift() async {
    try {
      developer.log('🔍 DebugGifts: Creating sample gift...');

      final sampleGift = {
        'name': 'هدية تجريبية',
        'points': 100,
        'stock': 10,
        'image_url': null,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response =
          await _supabase.from('gifts').insert(sampleGift).select().single();

      developer.log('✅ DebugGifts: Sample gift created: $response');
    } catch (e, stackTrace) {
      developer.log('❌ DebugGifts: Error creating sample gift: $e');
      developer.log('❌ DebugGifts: Stack trace: $stackTrace');
    }
  }

  /// Test user data retrieval
  static Future<void> testUserData(String userId) async {
    try {
      developer.log('🔍 DebugGifts: Testing user data for: $userId');

      final response =
          await _supabase.from('users').select().eq('id', userId).single();

      developer.log('🔍 DebugGifts: User data: $response');
      developer.log('🔍 DebugGifts: User points: ${response['points']}');
    } catch (e, stackTrace) {
      developer.log('❌ DebugGifts: Error testing user data: $e');
      developer.log('❌ DebugGifts: Stack trace: $stackTrace');
    }
  }

  /// Test gift request creation
  static Future<void> testGiftRequest(String userId, String giftId) async {
    try {
      developer.log('🔍 DebugGifts: Testing gift request creation...');

      final requestData = {
        'user_id': userId,
        'gift_id': giftId,
        'status': 'pending',
        'request_date': DateTime.now().toIso8601String(),
      };

      developer.log('🔍 DebugGifts: Request data: $requestData');

      // Test if gift_requests table exists
      final response =
          await _supabase
              .from('gift_requests')
              .insert(requestData)
              .select()
              .single();

      developer.log('✅ DebugGifts: Gift request created: $response');
    } catch (e, stackTrace) {
      developer.log('❌ DebugGifts: Error testing gift request: $e');
      developer.log('❌ DebugGifts: Stack trace: $stackTrace');

      // If gift_requests table doesn't exist, try the old table name
      try {
        developer.log(
          '🔍 DebugGifts: Trying alternative table name "requests"...',
        );

        final requestData = {
          'user_id': userId,
          'gift_id': giftId,
          'status': 'pending',
          'request_date': DateTime.now().toIso8601String(),
        };

        final response =
            await _supabase
                .from('requests')
                .insert(requestData)
                .select()
                .single();

        developer.log(
          '✅ DebugGifts: Gift request created in "requests" table: $response',
        );
      } catch (e2) {
        developer.log('❌ DebugGifts: Error with "requests" table: $e2');
      }
    }
  }
}
