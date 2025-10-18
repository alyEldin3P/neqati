import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:neqati/core/services/user_service.dart';

class QRCodeService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  // QR Code Operations
  Future<Map<String, dynamic>> createQRCode({
    required int points,
    required String branch,
    required int expiryDuration,
    required String encryptedPayload,
  }) async {
    final qrData = {
      'points': points,
      'branch': branch,
      'status': 'active',
      'scanned_by': null,
      'scan_date': null,
      'creation_date': DateTime.now().toIso8601String(),
      'expiry_duration': expiryDuration,
      'encrypted_payload': encryptedPayload,
    };

    final response =
        await _supabase.from('qr_codes').insert(qrData).select().single();

    return response;
  }

  Future<Map<String, dynamic>?> getQRCodeData(String qrId) async {
    try {
      final response =
          await _supabase.from('qr_codes').select().eq('id', qrId).single();

      return response;
    } catch (e) {
      log('Error getting QR code data: $e');
      return null;
    }
  }

  Future<bool> scanQRCode(String qrId, String userId) async {
    print('🔍 Starting QR code scan process...');
    print('🔍 QR ID: $qrId');
    print('🔍 User ID: $userId');

    // Get QR code data
    print('🔍 Fetching QR code data from database...');
    final qrData = await getQRCodeData(qrId);
    if (qrData == null) {
      print('❌ QR code not found in database');
      return false;
    }

    print('✅ QR code found: $qrData');

    // Check if QR code is active
    final status = qrData['status'];
    print('🔍 QR code status: $status');
    if (status != 'active') {
      print('❌ QR code is not active (status: $status)');
      return false;
    }

    // 🔒 RACE CONDITION PREVENTION: Try to atomically update status to 'scanned'
    // This prevents two devices from scanning the same QR code simultaneously
    print('🔒 Attempting atomic status update to prevent race condition...');
    try {
      final updateResult = await _supabase
          .from('qr_codes')
          .update({'status': 'scanned'})
          .eq('id', qrId)
          .eq('status', 'active') // Only update if still active
          .select();
      
      // If no rows were updated, another device already scanned this QR code
      if (updateResult.isEmpty) {
        print('❌ QR code was already scanned by another device (race condition prevented)');
        return false;
      }
      print('✅ Successfully claimed QR code for scanning');
    } catch (e) {
      print('❌ Error during atomic status update: $e');
      return false;
    }

    // Check if QR code is expired
    print('🔍 Checking QR code expiry...');
    final creationDate = DateTime.parse(qrData['creation_date']);
    final expiryDuration = qrData['expiry_duration'] as int? ?? 7;
    final expiryDate = creationDate.add(Duration(days: expiryDuration));

    print('🔍 Creation date: $creationDate');
    print('🔍 Expiry duration: $expiryDuration days');
    print('🔍 Expiry date: $expiryDate');
    print('🔍 Current date: ${DateTime.now()}');

    if (DateTime.now().isAfter(expiryDate)) {
      print('❌ QR code is expired - marking as expired');
      // Mark QR code as expired
      await _supabase
          .from('qr_codes')
          .update({'status': 'expired'})
          .eq('id', qrId);
      return false;
    }

    print('✅ QR code is not expired');

    // Get user data for level multiplier
    print('🔍 Getting user data for level multiplier...');
    final userData = await _userService.getUserData(userId);
    if (userData == null) {
      print('❌ User data not found');
      return false;
    }
    print('✅ User data found: $userData');

    // Get level multiplier
    final userLevel = userData['level'] as String? ?? 'مبتدئ';
    print('🔍 User level: $userLevel');

    print('🔍 Fetching level multiplier...');
    final levelResponse =
        await _supabase
            .from('levels')
            .select()
            .eq('name', userLevel)
            .limit(1)
            .single();

    double multiplier = 1.0;
    multiplier = levelResponse['multiplier'] as double? ?? 1.0;
    print('✅ Level multiplier: $multiplier');

    // Calculate points earned
    final basePoints = qrData['points'] as int? ?? 0;
    final pointsEarned = (basePoints * multiplier).toInt();
    print('🔍 Base points: $basePoints');
    print('🔍 Points earned (after multiplier): $pointsEarned');

    // Update QR code with additional scan details
    // Note: Status was already set to 'scanned' in the atomic update above
    print('🔍 Updating QR code with scan details...');
    final userName = userData['name'] as String? ?? 'مستخدم غير معروف';
    await _supabase
        .from('qr_codes')
        .update({
          'scanned_by': userId,
          'scanned_by_name': userName,
          'scan_date': DateTime.now().toIso8601String(),
        })
        .eq('id', qrId);
    print('✅ QR code scan details updated with user name: $userName');

    // Record scan in history
    print('🔍 Recording scan in history...');
    await _supabase.from('scans').insert({
      'user_id': userId,
      'scanned_by_name': userName,
      'qr_code_id': qrId,
      'points_earned': pointsEarned,
      'scan_date': DateTime.now().toIso8601String(),
      'branch': qrData['branch'],
    });
    print('✅ Scan recorded in history');

    // Update user points
    print('🔍 Updating user points...');
    await _userService.updateUserPoints(userId, pointsEarned);
    print('✅ User points updated');

    print('🎉 QR code scan completed successfully!');
    return true;
  }

  // QR Scan Record
  Future<Map<String, dynamic>> recordQRScan({
    required String userId,
    required Map<String, dynamic> qrData,
  }) async {
    print('🎯 Starting QR scan record process...');
    print('🎯 User ID: $userId');
    print('🎯 QR Data: $qrData');

    // Extract QR code ID from decrypted data
    final qrId = qrData['id'] as String?;
    print('🎯 Extracted QR ID: $qrId');

    if (qrId == null) {
      print('❌ QR ID is null - invalid QR code');
      return {
        'success': false,
        'message': 'رمز QR غير صالح',
        'points': 0,
        'location': '',
      };
    }

    // Attempt to scan the QR code
    print('🎯 Attempting to scan QR code...');
    final scanSuccess = await scanQRCode(qrId, userId);
    print('🎯 Scan result: $scanSuccess');

    if (!scanSuccess) {
      print('❌ Scan failed - determining failure reason...');
      // Get QR code data to determine why scan failed
      final qrCodeData = await getQRCodeData(qrId);
      String message = 'فشل مسح الرمز';

      if (qrCodeData == null) {
        message = 'رمز QR غير موجود';
        print('❌ Failure reason: QR code not found');
      } else if (qrCodeData['status'] == 'scanned') {
        message = 'تم مسح هذا الرمز مسبقاً';
        print('❌ Failure reason: QR code already scanned');
      } else if (qrCodeData['status'] == 'expired') {
        message = 'انتهت صلاحية هذا الرمز';
        print('❌ Failure reason: QR code expired');
      } else {
        print('❌ Failure reason: Unknown (status: ${qrCodeData['status']})');
      }

      final failureResult = {
        'success': false,
        'message': message,
        'points': 0,
        'location': qrCodeData?['branch'] ?? '',
      };
      print('❌ Returning failure result: $failureResult');
      return failureResult;
    }

    // Get the latest scan for this user and QR code
    print('🎯 Scan successful - fetching scan details...');
    try {
      final scanResponse =
          await _supabase
              .from('scans')
              .select()
              .eq('user_id', userId)
              .eq('qr_code_id', qrId)
              .order('scan_date', ascending: false)
              .limit(1)
              .single();

      print('✅ Scan details retrieved: $scanResponse');

      final successResult = {
        'success': true,
        'message': 'تم مسح الرمز بنجاح',
        'points': scanResponse['points_earned'] ?? 0,
        'location': scanResponse['branch'] ?? '',
      };
      print('🎉 Returning success result: $successResult');
      return successResult;
    } catch (e) {
      print('❌ Error fetching scan details: $e');
      final errorResult = {
        'success': false,
        'message': 'حدث خطأ أثناء تسجيل المسح',
        'points': 0,
        'location': qrData['branch'] ?? '',
      };
      print('❌ Returning error result: $errorResult');
      return errorResult;
    }
  }

  // Admin QR Code Management
  Future<List<Map<String, dynamic>>> getAllQRCodes() async {
    try {
      final response = await _supabase.from('qr_codes').select();

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get all QR codes: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getQRCodesPaginated({
    int limit = 10,
    int offset = 0,
    String? searchQuery,
    String? statusFilter,
  }) async {
    try {
      // Build query based on status filter
      dynamic response;
      
      if (statusFilter == 'used') {
        response = await _supabase
            .from('qr_codes')
            .select()
            .eq('status', 'scanned')
            .range(offset, offset + limit - 1)
            .order('creation_date', ascending: false);
      } else if (statusFilter == 'unused') {
        response = await _supabase
            .from('qr_codes')
            .select()
            .neq('status', 'scanned')
            .range(offset, offset + limit - 1)
            .order('creation_date', ascending: false);
      } else {
        // 'all' or null - no status filter
        response = await _supabase
            .from('qr_codes')
            .select()
            .range(offset, offset + limit - 1)
            .order('creation_date', ascending: false);
      }

      // Note: For search functionality, we'll filter on the client side for now
      // or implement server-side search with proper text search configuration

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get QR codes: $e');
    }
  }

  Future<int> getQRCodesCount({String? statusFilter}) async {
    try {
      dynamic response;
      
      if (statusFilter == 'used') {
        response = await _supabase
            .from('qr_codes')
            .select('id')
            .eq('status', 'scanned');
      } else if (statusFilter == 'unused') {
        response = await _supabase
            .from('qr_codes')
            .select('id')
            .neq('status', 'scanned');
      } else {
        // 'all' or null - no status filter
        response = await _supabase.from('qr_codes').select('id');
      }

      return response.length;
    } catch (e) {
      throw Exception('Failed to get QR codes count: $e');
    }
  }

  Future<String> createQRCodeAdmin({
    required int points,
    required String branch,
    required int expiryDuration,
    String? encryptedPayload,
  }) async {
    try {
      print('💾 Creating QR code in database with:');
      print('   - points: $points');
      print('   - branch: $branch');
      print('   - expiryDuration: $expiryDuration');
      print(
        '   - encryptedPayload: ${encryptedPayload?.substring(0, 20) ?? 'null'}...',
      );

      // Generate a unique QR code ID
      final qrCodeData = {
        'points': points,
        'branch': branch,
        'status': 'active',
        'creation_date': DateTime.now().toIso8601String(),
        'expiry_duration': expiryDuration,
        'scanned_by': null,
        'scan_date': null,
        'encrypted_payload': encryptedPayload,
      };

      print('💾 Inserting QR code data: $qrCodeData');
      final response =
          await _supabase.from('qr_codes').insert(qrCodeData).select().single();

      final qrCodeId = response['id'] as String;
      print('💾 QR code created successfully with ID: $qrCodeId');
      return qrCodeId;
    } catch (e) {
      print('❌ Error creating QR code in database: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Failed to create QR code: $e');
    }
  }

  Future<void> updateQRCodePayload(
    String qrCodeId,
    String encryptedPayload,
  ) async {
    try {
      print('🔄 Updating QR code payload for ID: $qrCodeId');
      print('🔄 Payload length: ${encryptedPayload.length}');
      print('🔄 Payload preview: ${encryptedPayload.substring(0, 50)}...');

      await _supabase
          .from('qr_codes')
          .update({'encrypted_payload': encryptedPayload})
          .eq('id', qrCodeId);

      print('✅ QR code payload updated successfully');
    } catch (e) {
      print('❌ Error updating QR code payload: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Failed to update QR code payload: $e');
    }
  }

  Future<void> deleteQRCode(String qrCodeId) async {
    try {
      await _supabase.from('qr_codes').delete().eq('id', qrCodeId);
    } catch (e) {
      throw Exception('Failed to delete QR code: $e');
    }
  }
}
