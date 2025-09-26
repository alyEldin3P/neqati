import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

/// Debug utility to test gifts table and troubleshoot issues
class DebugGifts {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Test the gifts table structure and data
  static Future<void> testGiftsTable() async {
    try {
      developer.log('🔍 DebugGifts: Testing gifts table...');
      
      // Test 1: Check if gifts table exists and get all data
      final response = await _supabase
          .from('gifts')
          .select()
          .limit(10);
      
      developer.log('🔍 DebugGifts: Raw response: $response');
      developer.log('🔍 DebugGifts: Response type: ${response.runtimeType}');
      developer.log('🔍 DebugGifts: Response length: ${response.length}');
      
      if (response.isEmpty) {
        developer.log('⚠️ DebugGifts: No gifts found in database');
        
        // Test 2: Try to create a sample gift for testing
        await createSampleGift();
      } else {
        developer.log('✅ DebugGifts: Found ${response.length} gifts');
        
        // Test 3: Analyze the structure of the first gift
        final firstGift = response[0];
        developer.log('🔍 DebugGifts: First gift structure: $firstGift');
        developer.log('🔍 DebugGifts: First gift keys: ${firstGift.keys.toList()}');
        
        // Test 4: Check specific fields
        final id = firstGift['id'];
        final name = firstGift['name'];
        final points = firstGift['points'];
        final stock = firstGift['stock'];
        final imageUrl = firstGift['image_url'];
        final createdAt = firstGift['created_at'];
        
        developer.log('🔍 DebugGifts: Field analysis:');
        developer.log('  - id: $id (${id.runtimeType})');
        developer.log('  - name: $name (${name.runtimeType})');
        developer.log('  - points: $points (${points.runtimeType})');
        developer.log('  - stock: $stock (${stock.runtimeType})');
        developer.log('  - image_url: $imageUrl (${imageUrl.runtimeType})');
        developer.log('  - created_at: $createdAt (${createdAt.runtimeType})');
      }
      
    } catch (e, stackTrace) {
      developer.log('❌ DebugGifts: Error testing gifts table: $e');
      developer.log('❌ DebugGifts: Stack trace: $stackTrace');
    }
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
      
      final response = await _supabase
          .from('gifts')
          .insert(sampleGift)
          .select()
          .single();
      
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
      
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      
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
      final response = await _supabase
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
        developer.log('🔍 DebugGifts: Trying alternative table name "requests"...');
        
        final requestData = {
          'user_id': userId,
          'gift_id': giftId,
          'status': 'pending',
          'request_date': DateTime.now().toIso8601String(),
        };
        
        final response = await _supabase
            .from('requests')
            .insert(requestData)
            .select()
            .single();
        
        developer.log('✅ DebugGifts: Gift request created in "requests" table: $response');
        
      } catch (e2) {
        developer.log('❌ DebugGifts: Error with "requests" table: $e2');
      }
    }
  }
}
