# FCM Implementation Notes

## ✅ Implementation Complete

The `_sendNotificationToToken` method has been successfully implemented using Firebase Cloud Messaging HTTP v1 API with OAuth2 authentication.

## 🔧 What Was Implemented

### 1. Dependencies Added
- `http: ^1.2.0` - HTTP client for making API requests
- `googleapis_auth: ^1.6.0` - OAuth2 authentication for FCM API

### 2. New Methods in FCMNotificationService

#### `_getAccessToken()`
- Obtains OAuth2 access token using service account credentials
- Caches token for 55 minutes (tokens expire in 1 hour)
- Automatically refreshes expired tokens
- Uses `googleapis_auth` package for authentication

#### `_sendNotificationToToken()` (Updated)
- Sends push notifications using FCM HTTP v1 API
- Makes authenticated POST request to FCM endpoint
- Includes notification title, body, and custom data
- Supports both Android and iOS platforms
- Proper error handling and logging

## 📋 Configuration Required

Before the notifications will work, you need to:

### 1. Get Firebase Service Account Credentials
1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate New Private Key"
3. Download the JSON file

### 2. Update FCMNotificationService
Open `/lib/core/services/fcm_notification_service.dart` and replace:

```dart
// Line 16: Replace with your Firebase project ID
static const String _fcmProjectId = 'YOUR_FIREBASE_PROJECT_ID';

// Lines 21-34: Replace with your service account JSON
static const String _serviceAccountJson = '''
{
  "type": "service_account",
  "project_id": "your-project-id",
  // ... paste your service account JSON here
}
''';
```

### 3. Run Flutter Pub Get
```bash
flutter pub get
```

## 🔐 Security Considerations

### ⚠️ Important Security Notes:

1. **Never commit service account credentials to Git**
   - Add to `.gitignore` if storing in a separate file
   - Use environment variables in production
   - Consider using Flutter's `--dart-define` for secrets

2. **Production Recommendation**
   - Implement a backend server (Node.js, Cloud Functions, etc.)
   - Move service account credentials to backend
   - Flutter app calls backend, backend calls FCM
   - This keeps credentials secure server-side

3. **Alternative Secure Approaches**
   - Use Firebase Cloud Functions (serverless)
   - Use Flutter secure storage for credentials
   - Implement credential encryption

## 🚀 How It Works

### Authentication Flow
```
1. App needs to send notification
2. _getAccessToken() is called
3. Service account credentials are used to get OAuth2 token
4. Token is cached for 55 minutes
5. Token is used in Authorization header
```

### Notification Flow
```
1. User requests a gift
2. GiftService calls FCMNotificationService
3. Admin tokens are fetched from database
4. For each admin token:
   - Get OAuth2 access token
   - Construct FCM API request
   - Send POST to FCM endpoint
   - Handle response
5. Success/failure logged
```

### API Request Structure
```json
POST https://fcm.googleapis.com/v1/projects/{project-id}/messages:send
Headers:
  Content-Type: application/json
  Authorization: Bearer {access-token}

Body:
{
  "message": {
    "token": "device-token",
    "notification": {
      "title": "طلب هدية جديد",
      "body": "أحمد طلب هدية: قسيمة شراء (100 نقطة)"
    },
    "data": {
      "type": "gift_request",
      "user_id": "...",
      "gift_id": "...",
      ...
    },
    "android": {
      "priority": "high",
      "notification": {
        "sound": "default",
        "channel_id": "neqati_notifications"
      }
    },
    "apns": {
      "payload": {
        "aps": {
          "sound": "default",
          "badge": 1
        }
      }
    }
  }
}
```

## 🧪 Testing

### 1. Test Token Caching
```dart
// First call - fetches new token
await _sendNotificationToToken(...);

// Second call within 55 minutes - uses cached token
await _sendNotificationToToken(...);
```

### 2. Test Notification Sending
```dart
// In your app, request a gift as a regular user
// Check logs for:
// - "🔔 FCMNotificationService: Fetching new access token..."
// - "✅ FCMNotificationService: Access token obtained"
// - "🔔 FCMNotificationService: Sending notification to token..."
// - "✅ FCMNotificationService: Notification sent successfully"
```

### 3. Verify on Admin Device
- Admin user should receive push notification
- Notification should show title and body
- Tapping notification should open app with data

## 📊 Monitoring

### Success Indicators
- ✅ Status code 200 from FCM API
- ✅ Response contains message ID
- ✅ Admin receives notification on device

### Error Indicators
- ❌ 401 Unauthorized - Invalid credentials or expired token
- ❌ 404 Not Found - Invalid project ID or token
- ❌ 400 Bad Request - Invalid payload format

### Debug Logs
All operations are logged with emoji prefixes:
- 🔔 - Info/Progress
- ✅ - Success
- ❌ - Error

Search logs for `FCMNotificationService` to track all operations.

## 🔄 Next Steps

1. **Configure Service Account** (Required)
   - Get credentials from Firebase Console
   - Update `_fcmProjectId` and `_serviceAccountJson`

2. **Test Notifications** (Recommended)
   - Test with one admin user first
   - Verify notification delivery
   - Check logs for errors

3. **Production Setup** (Recommended)
   - Move to backend server for security
   - Implement proper error handling
   - Add retry logic for failed sends
   - Monitor delivery rates

4. **Enhancements** (Optional)
   - Add notification history tracking
   - Implement notification preferences
   - Add notification categories
   - Support notification actions

## 📚 References

- [FCM HTTP v1 API Documentation](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages)
- [OAuth2 for Server to Server Applications](https://developers.google.com/identity/protocols/oauth2/service-account)
- [googleapis_auth Package](https://pub.dev/packages/googleapis_auth)
- [FCM Setup Guide](./FCM_SETUP_GUIDE.md)

## ✨ Summary

The FCM notification system is now fully implemented and ready to use once you configure the service account credentials. The implementation uses industry-standard OAuth2 authentication and follows Firebase's recommended practices for sending notifications.
