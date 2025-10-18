import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:http/http.dart' as http;

/// FCM Notification Service for sending push notifications
/// Uses FCM Legacy API (works without Cloud Functions - perfect for free Firebase plan)
class FCMNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  // FCM Configuration - Legacy API
  // Get it from: Firebase Console → Project Settings → Cloud Messaging → Server Key
  static const String _fcmServerKey = 'YOUR_FCM_SERVER_KEY_HERE';

  // FCM Legacy API endpoint
  static const String _fcmLegacyUrl = 'https://fcm.googleapis.com/fcm/send';

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    try {
      developer.log('🔔 FCMNotificationService: Initializing FCM...');

      // Request notification permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      developer.log(
        '🔔 FCMNotificationService: Permission status: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        developer.log('🔔 FCMNotificationService: User granted permission');

        // Get FCM token
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          developer.log(
            '🔔 FCMNotificationService: FCM Token obtained: ${token.substring(0, 20)}...',
          );

          // Save token to database
          await _saveDeviceToken(token);
        } else {
          developer.log('⚠️ FCMNotificationService: Failed to get FCM token');
        }

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          developer.log('🔔 FCMNotificationService: Token refreshed');
          _saveDeviceToken(newToken);
        });

        // Setup foreground message handler
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      } else {
        developer.log('⚠️ FCMNotificationService: User declined permission');
      }
    } catch (e, stackTrace) {
      developer.log('❌ FCMNotificationService: Error initializing FCM: $e');
      developer.log('❌ FCMNotificationService: Stack trace: $stackTrace');
    }
  }

  /// Save device token to database (public method for manual token saving)
  Future<void> saveDeviceToken() async {
    try {
      developer.log(
        '🔔 FCMNotificationService: Manually saving device token...',
      );
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveDeviceToken(token);
      } else {
        developer.log('⚠️ FCMNotificationService: No FCM token available');
      }
    } catch (e) {
      developer.log('❌ FCMNotificationService: Error in saveDeviceToken: $e');
    }
  }

  /// Save device token to database (internal method)
  Future<void> _saveDeviceToken(String token) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        developer.log(
          '⚠️ FCMNotificationService: No user logged in, cannot save token',
        );
        return;
      }

      developer.log(
        '🔔 FCMNotificationService: Saving device token for user: ${currentUser.id}',
      );

      await _supabase
          .from('users')
          .update({'device_token': token})
          .eq('id', currentUser.id);

      developer.log(
        '✅ FCMNotificationService: Device token saved successfully',
      );
    } catch (e) {
      developer.log('❌ FCMNotificationService: Error saving device token: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    developer.log('🔔 FCMNotificationService: Foreground message received');
    developer.log('🔔 Title: ${message.notification?.title}');
    developer.log('🔔 Body: ${message.notification?.body}');
    developer.log('🔔 Data: ${message.data}');
  }

  /// Get all admin device tokens from database
  Future<List<String>> _getAdminDeviceTokens() async {
    try {
      developer.log(
        '🔔 FCMNotificationService: Fetching admin device tokens...',
      );

      final response = await _supabase
          .from('users')
          .select('device_token')
          .eq('is_admin', true)
          .not('device_token', 'is', null);

      final tokens = <String>[];
      for (final row in response) {
        final token = row['device_token'] as String?;
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }

      developer.log(
        '🔔 FCMNotificationService: Found ${tokens.length} admin tokens',
      );
      return tokens;
    } catch (e) {
      developer.log(
        '❌ FCMNotificationService: Error fetching admin tokens: $e',
      );
      return [];
    }
  }

  /// Send gift request notification to all admins using FCM Legacy API
  Future<void> sendGiftRequestNotificationToAdmins({
    required String userName,
    required String giftName,
    required int giftPoints,
    required String userId,
    required String giftId,
  }) async {
    try {
      developer.log(
        '🔔 FCMNotificationService: ========== SENDING ADMIN NOTIFICATION ==========',
      );
      developer.log('🔔 FCMNotificationService: User: $userName');
      developer.log('🔔 FCMNotificationService: Gift: $giftName');
      developer.log('🔔 FCMNotificationService: Points: $giftPoints');

      // Get all admin device tokens
      final adminTokens = await _getAdminDeviceTokens();

      if (adminTokens.isEmpty) {
        developer.log(
          '⚠️ FCMNotificationService: No admin tokens found, skipping notification',
        );
        return;
      }

      developer.log(
        '🔔 FCMNotificationService: Sending to ${adminTokens.length} admin devices',
      );

      // Prepare notification payload
      final notification = {
        'title': 'طلب هدية جديد',
        'body': '$userName طلب هدية: $giftName ($giftPoints نقطة)',
      };

      final data = {
        'type': 'gift_request',
        'user_id': userId,
        'user_name': userName,
        'gift_id': giftId,
        'gift_name': giftName,
        'gift_points': giftPoints.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Send notification to each admin token
      int successCount = 0;
      int failureCount = 0;

      for (final token in adminTokens) {
        try {
          await _sendNotificationToToken(
            token: token,
            notification: notification,
            data: data,
          );
          successCount++;
        } catch (e) {
          developer.log(
            '❌ FCMNotificationService: Failed to send to token: $e',
          );
          failureCount++;
        }
      }

      developer.log(
        '✅ FCMNotificationService: Notifications sent - Success: $successCount, Failed: $failureCount',
      );
      developer.log(
        '🔔 FCMNotificationService: ========== NOTIFICATION COMPLETE ==========',
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ FCMNotificationService: Error sending admin notification: $e',
      );
      developer.log('❌ FCMNotificationService: Stack trace: $stackTrace');
    }
  }

  /// Send notification to a specific token using FCM Legacy API
  /// This works without Cloud Functions - perfect for free Firebase plan!
  Future<void> _sendNotificationToToken({
    required String token,
    required Map<String, String> notification,
    required Map<String, String> data,
  }) async {
    try {
      developer.log(
        '🔔 FCMNotificationService: ========================================',
      );
      developer.log(
        '🔔 FCMNotificationService: Sending notification via Legacy API',
      );
      developer.log(
        '🔔 FCMNotificationService: Target token: ${token.substring(0, 20)}...',
      );
      developer.log(
        '🔔 FCMNotificationService: Server key configured: ${_fcmServerKey != "YOUR_FCM_SERVER_KEY_HERE" ? "YES ✅" : "NO ❌ - Please update _fcmServerKey"}',
      );
      developer.log(
        '🔔 FCMNotificationService: API endpoint: $_fcmLegacyUrl',
      );

      // Check if server key is configured
      if (_fcmServerKey == 'YOUR_FCM_SERVER_KEY_HERE') {
        developer.log(
          '❌ FCMNotificationService: FCM Server Key not configured!',
        );
        developer.log(
          '❌ FCMNotificationService: Please update _fcmServerKey in fcm_notification_service.dart',
        );
        developer.log(
          '❌ FCMNotificationService: Get it from: Firebase Console → Project Settings → Cloud Messaging → Server Key',
        );
        throw Exception(
          'FCM Server Key not configured. Please update _fcmServerKey constant.',
        );
      }

      // Prepare the FCM Legacy API payload
      final payload = {
        'to': token,
        'notification': {
          'title': notification['title'],
          'body': notification['body'],
          'sound': 'default',
        },
        'data': data,
        'priority': 'high',
        'content_available': true,
      };

      developer.log(
        '🔔 FCMNotificationService: Request payload prepared',
      );
      developer.log(
        '🔔 FCMNotificationService: Notification title: ${notification['title']}',
      );
      developer.log(
        '🔔 FCMNotificationService: Notification body: ${notification['body']}',
      );
      developer.log(
        '🔔 FCMNotificationService: Data fields: ${data.keys.join(", ")}',
      );

      // Send the HTTP request to FCM Legacy API
      developer.log(
        '🔔 FCMNotificationService: Sending HTTP POST request...',
      );
      
      final response = await http.post(
        Uri.parse(_fcmLegacyUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_fcmServerKey',
        },
        body: jsonEncode(payload),
      );

      developer.log(
        '🔔 FCMNotificationService: Response received',
      );
      developer.log(
        '🔔 FCMNotificationService: Status code: ${response.statusCode}',
      );
      developer.log(
        '🔔 FCMNotificationService: Response headers: ${response.headers}',
      );
      developer.log(
        '🔔 FCMNotificationService: Response body: ${response.body}',
      );

      // Check response status
      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          developer.log(
            '✅ FCMNotificationService: HTTP request successful (200 OK)',
          );
          developer.log(
            '✅ FCMNotificationService: Multicast ID: ${responseData['multicast_id']}',
          );
          developer.log(
            '✅ FCMNotificationService: Success count: ${responseData['success']}',
          );
          developer.log(
            '✅ FCMNotificationService: Failure count: ${responseData['failure']}',
          );

          // Check if the message was delivered
          if (responseData['success'] == 1) {
            developer.log(
              '✅ FCMNotificationService: ✨ Message delivered successfully to device!',
            );
            developer.log(
              '✅ FCMNotificationService: Message ID: ${responseData['results']?[0]?['message_id']}',
            );
          } else if (responseData['failure'] == 1) {
            developer.log(
              '⚠️ FCMNotificationService: Message failed to deliver',
            );
            developer.log(
              '⚠️ FCMNotificationService: Error details: ${responseData['results']}',
            );
            final errorResult = responseData['results']?[0];
            if (errorResult != null && errorResult['error'] != null) {
              developer.log(
                '⚠️ FCMNotificationService: Error code: ${errorResult['error']}',
              );
            }
          }
        } catch (jsonError) {
          developer.log(
            '⚠️ FCMNotificationService: Could not parse response JSON: $jsonError',
          );
          developer.log(
            '⚠️ FCMNotificationService: Raw response: ${response.body}',
          );
        }
      } else {
        developer.log(
          '❌ FCMNotificationService: HTTP request failed',
        );
        developer.log(
          '❌ FCMNotificationService: Status code: ${response.statusCode}',
        );
        developer.log(
          '❌ FCMNotificationService: Status message: ${response.reasonPhrase}',
        );
        developer.log(
          '❌ FCMNotificationService: Response body: ${response.body}',
        );
        developer.log(
          '❌ FCMNotificationService: Response headers: ${response.headers}',
        );
        
        // Provide specific guidance based on status code
        if (response.statusCode == 401) {
          developer.log(
            '❌ FCMNotificationService: AUTHENTICATION ERROR - Invalid server key',
          );
          developer.log(
            '❌ FCMNotificationService: Please verify your FCM Server Key in Firebase Console',
          );
        } else if (response.statusCode == 404) {
          developer.log(
            '❌ FCMNotificationService: NOT FOUND ERROR',
          );
          developer.log(
            '❌ FCMNotificationService: This usually means:',
          );
          developer.log(
            '   1. FCM Legacy API is not enabled for your project',
          );
          developer.log(
            '   2. Or the server key is incorrect',
          );
          developer.log(
            '   3. Or Cloud Messaging API needs to be enabled',
          );
          developer.log(
            '❌ FCMNotificationService: Please check Firebase Console → Cloud Messaging',
          );
        }
        
        throw Exception(
          'Failed to send notification: ${response.statusCode} - ${response.reasonPhrase ?? "Unknown error"}',
        );
      }
      
      developer.log(
        '🔔 FCMNotificationService: ========================================',
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ FCMNotificationService: EXCEPTION in _sendNotificationToToken',
      );
      developer.log('❌ FCMNotificationService: Error: $e');
      developer.log('❌ FCMNotificationService: Error type: ${e.runtimeType}');
      developer.log('❌ FCMNotificationService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Clear device token on logout
  Future<void> clearDeviceToken() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      developer.log(
        '🔔 FCMNotificationService: Clearing device token for user: ${currentUser.id}',
      );

      await _supabase
          .from('users')
          .update({'device_token': null})
          .eq('id', currentUser.id);

      developer.log('✅ FCMNotificationService: Device token cleared');
    } catch (e) {
      developer.log(
        '❌ FCMNotificationService: Error clearing device token: $e',
      );
    }
  }
}
