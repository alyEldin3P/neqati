import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:neqati/core/services/user_service.dart';
import 'dart:developer' as developer;

class GiftService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  // Gift Operations
  Future<List<Map<String, dynamic>>> getAvailableGifts() async {
    try {
      developer.log('🎁 GiftService: Starting to fetch available gifts');

      final response = await _supabase
          .from('gifts')
          .select()
          .order('created_at', ascending: false);

      developer.log('🎁 GiftService: Raw response from gifts table: $response');
      developer.log('🎁 GiftService: Response type: ${response.runtimeType}');
      developer.log('🎁 GiftService: Response length: ${response.length}');

      if (response.isNotEmpty) {
        developer.log('🎁 GiftService: First gift data: ${response[0]}');
        developer.log(
          '🎁 GiftService: First gift keys: ${response[0].keys.toList()}',
        );
      }

      final gifts = List<Map<String, dynamic>>.from(response);
      developer.log(
        '🎁 GiftService: Successfully fetched ${gifts.length} gifts',
      );

      return gifts;
    } catch (e, stackTrace) {
      developer.log('❌ GiftService: Error fetching gifts: $e');
      developer.log('❌ GiftService: Stack trace: $stackTrace');
      throw Exception('Failed to get available gifts: $e');
    }
  }

  Future<bool> requestGift(String userId, String giftId) async {
    try {
      developer.log(
        '🎁 GiftService: Starting gift request for user: $userId, gift: $giftId',
      );

      // Get user data
      final userData = await _userService.getUserData(userId);
      if (userData == null) {
        developer.log('❌ GiftService: User data not found for user: $userId');
        return false;
      }

      developer.log('🎁 GiftService: User data: $userData');

      // Get gift data
      final giftResponse =
          await _supabase.from('gifts').select().eq('id', giftId).single();

      developer.log('🎁 GiftService: Gift data: $giftResponse');

      // Check if user has enough points
      final userPoints = userData['points'] as int? ?? 0;
      final giftPoints = giftResponse['points'] as int? ?? 0;

      developer.log(
        '🎁 GiftService: User points: $userPoints, Required points: $giftPoints',
      );

      if (userPoints < giftPoints) {
        developer.log(
          '❌ GiftService: Insufficient points. User: $userPoints, Required: $giftPoints',
        );
        return false;
      }

      // Check if gift is in stock
      final stock = giftResponse['stock'] as int? ?? 0;
      developer.log('🎁 GiftService: Gift stock: $stock');

      if (stock <= 0) {
        developer.log('❌ GiftService: Gift out of stock');
        return false;
      }

      // Create gift request
      final requestData = {
        'user_id': userId,
        'gift_id': giftId,
        'status': 'pending',
        'request_date': DateTime.now().toIso8601String(),
      };

      developer.log('🎁 GiftService: Creating gift request: $requestData');

      await _supabase.from('gift_requests').insert(requestData);

      developer.log('🎁 GiftService: Gift request created successfully');

      // Note: Notification creation skipped - notifications table doesn't exist
      // TODO: Create notifications table if admin notifications are needed
      developer.log(
        '🎁 GiftService: Skipping notification creation (table not found)',
      );

      developer.log('🎁 GiftService: Gift request completed successfully');

      return true;
    } catch (e, stackTrace) {
      developer.log('❌ GiftService: Error requesting gift: $e');
      developer.log('❌ GiftService: Stack trace: $stackTrace');
      return false;
    }
  }

  Future<Map<String, dynamic>> redeemGift(String giftId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'يرجى تسجيل الدخول أولاً'};
      }

      // Get gift details
      final giftResponse =
          await _supabase.from('gifts').select().eq('id', giftId).single();

      final requiredPoints = giftResponse['required_points'] as int? ?? 0;
      final isAvailable = giftResponse['is_available'] as bool? ?? false;

      if (!isAvailable) {
        return {'success': false, 'message': 'هذه الهدية غير متاحة حالياً'};
      }

      // Get user points
      final userData = await _userService.getUserData(currentUser.id);
      if (userData == null) {
        return {'success': false, 'message': 'بيانات المستخدم غير موجودة'};
      }

      final userPoints = userData['points'] as int? ?? 0;

      if (userPoints < requiredPoints) {
        return {
          'success': false,
          'message': 'نقاطك غير كافية لاستبدال هذه الهدية',
        };
      }

      // Create redemption record
      await _supabase.from('gift_redemptions').insert({
        'user_id': currentUser.id,
        'gift_id': giftId,
        'gift_name': giftResponse['name'],
        'points_used': requiredPoints,
        'redeemed_at': DateTime.now().toIso8601String(),
        'status': 'pending', // pending, approved, delivered
      });

      // Deduct points from user
      await _supabase
          .from('users')
          .update({'points': userPoints - requiredPoints})
          .eq('id', currentUser.id);

      return {
        'success': true,
        'message': 'تم استبدال الهدية بنجاح. سيتم التواصل معك قريباً',
      };
    } catch (e) {
      throw Exception('Failed to redeem gift: $e');
    }
  }

  // Admin Gift Management
  Future<List<Map<String, dynamic>>> getAllGifts() async {
    try {
      final response = await _supabase
          .from('gifts')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get gifts: $e');
    }
  }

  Future<String> createGift({
    required String name,
    required int points,
    required int stock,
    required String imageUrl,
  }) async {
    try {
      final giftData = {
        'name': name,
        'points': points,
        'stock': stock,
        'image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response =
          await _supabase.from('gifts').insert(giftData).select().single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create gift: $e');
    }
  }

  Future<void> updateGift({
    required String giftId,
    required Map<String, dynamic> giftData,
  }) async {
    try {
      await _supabase.from('gifts').update(giftData).eq('id', giftId);
    } catch (e) {
      throw Exception('Failed to update gift: $e');
    }
  }

  Future<void> deleteGift(String giftId) async {
    try {
      await _supabase.from('gifts').delete().eq('id', giftId);
    } catch (e) {
      throw Exception('Failed to delete gift: $e');
    }
  }

  Future<Map<String, dynamic>?> getGiftById(String giftId) async {
    try {
      final response =
          await _supabase.from('gifts').select().eq('id', giftId).single();

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getGiftRequests(String giftId) async {
    try {
      final response = await _supabase
          .from('gift_requests')
          .select('*, users!gift_requests_user_id_fkey(name, phone_number)')
          .eq('gift_id', giftId)
          .order('request_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get gift requests: $e');
    }
  }

  // Get all pending gift requests for admin dashboard
  Future<List<Map<String, dynamic>>> getAllPendingGiftRequests() async {
    try {
      developer.log('🎁 GiftService: Fetching all pending gift requests...');

      final response = await _supabase
          .from('gift_requests')
          .select(
            '*, users!gift_requests_user_id_fkey(name, phone_number, email), gifts!gift_requests_gift_id_fkey(name, points)',
          )
          .eq('status', 'pending')
          .order('request_date', ascending: false);

      developer.log(
        '🎁 GiftService: Found ${response.length} pending gift requests',
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      developer.log('❌ GiftService: Error fetching pending gift requests: $e');
      throw Exception('Failed to get pending gift requests: $e');
    }
  }

  // Get all gift requests (for admin management)
  Future<List<Map<String, dynamic>>> getAllGiftRequests() async {
    try {
      developer.log('🎁 GiftService: Fetching all gift requests...');

      final response = await _supabase
          .from('gift_requests')
          .select(
            '*, users!gift_requests_user_id_fkey(name, phone_number, email), gifts!gift_requests_gift_id_fkey(name, points)',
          )
          .order('request_date', ascending: false);

      developer.log(
        '🎁 GiftService: Found ${response.length} total gift requests',
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      developer.log('❌ GiftService: Error fetching all gift requests: $e');
      throw Exception('Failed to get all gift requests: $e');
    }
  }

  Future<void> updateGiftRequestStatus(String requestId, String status) async {
    try {
      await _supabase
          .from('gift_requests')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Failed to update gift request status: $e');
    }
  }

  // Get gift requests for a specific user
  Future<List<Map<String, dynamic>>> getUserGiftRequests(String userId) async {
    try {
      developer.log('🎁 GiftService: Fetching gift requests for user: $userId');

      final response = await _supabase
          .from('gift_requests')
          .select(
            '*, gifts!gift_requests_gift_id_fkey(name, points, image_url)',
          )
          .eq('user_id', userId)
          .order('request_date', ascending: false);

      developer.log(
        '🎁 GiftService: Found ${response.length} gift requests for user',
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      developer.log('❌ GiftService: Error fetching user gift requests: $e');
      throw Exception('Failed to get user gift requests: $e');
    }
  }

  // Approve gift request (admin action)
  Future<void> approveGiftRequest(String requestId, String adminNotes) async {
    try {
      developer.log('🎁 GiftService: Approving gift request: $requestId');

      // Get the gift request details
      final requestResponse =
          await _supabase
              .from('gift_requests')
              .select('*, gifts!gift_requests_gift_id_fkey(points)')
              .eq('id', requestId)
              .single();

      final userId = requestResponse['user_id'] as String;
      final giftPoints = requestResponse['gifts']['points'] as int;

      developer.log(
        '🎁 GiftService: Gift request details - User: $userId, Points: $giftPoints',
      );

      // Get user current points
      final userData = await _userService.getUserData(userId);
      if (userData == null) {
        throw Exception('User not found');
      }

      final currentPoints = userData['points'] as int? ?? 0;
      final newPoints = currentPoints - giftPoints;

      developer.log(
        '🎁 GiftService: User points - Current: $currentPoints, After deduction: $newPoints',
      );

      if (newPoints < 0) {
        throw Exception('User does not have enough points');
      }

      // Start transaction-like operations
      // 1. Update gift request status
      await _supabase
          .from('gift_requests')
          .update({
            'status': 'approved',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      // 2. Deduct points from user
      await _supabase
          .from('users')
          .update({'points': newPoints})
          .eq('id', userId);

      developer.log('🎁 GiftService: Gift request approved successfully');
    } catch (e) {
      developer.log('❌ GiftService: Error approving gift request: $e');
      throw Exception('Failed to approve gift request: $e');
    }
  }

  // Reject gift request (admin action)
  Future<void> rejectGiftRequest(String requestId, String adminNotes) async {
    try {
      developer.log('🎁 GiftService: Rejecting gift request: $requestId');

      await _supabase
          .from('gift_requests')
          .update({
            'status': 'rejected',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      developer.log('🎁 GiftService: Gift request rejected successfully');
    } catch (e) {
      developer.log('❌ GiftService: Error rejecting gift request: $e');
      throw Exception('Failed to reject gift request: $e');
    }
  }

  // Delete gift request (user action - only for pending requests)
  Future<void> deleteUserGiftRequest(String requestId, String userId) async {
    try {
      developer.log(
        '🎁 GiftService: Deleting gift request: $requestId for user: $userId',
      );

      // First check if the request belongs to the user and is pending
      final requestResponse =
          await _supabase
              .from('gift_requests')
              .select('user_id, status')
              .eq('id', requestId)
              .single();

      final requestUserId = requestResponse['user_id'] as String;
      final requestStatus = requestResponse['status'] as String;

      if (requestUserId != userId) {
        throw Exception('Unauthorized: Request does not belong to user');
      }

      if (requestStatus != 'pending') {
        throw Exception('Cannot delete non-pending request');
      }

      // Delete the request
      await _supabase
          .from('gift_requests')
          .delete()
          .eq('id', requestId)
          .eq('user_id', userId); // Double check for security

      developer.log('🎁 GiftService: Gift request deleted successfully');
    } catch (e) {
      developer.log('❌ GiftService: Error deleting gift request: $e');
      throw Exception('Failed to delete gift request: $e');
    }
  }
}
