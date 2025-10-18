# Firebase Cloud Messaging (FCM) Setup Guide for Neqati App

This guide explains how to set up Firebase Cloud Messaging (FCM) for push notifications in the Neqati app.

## Overview

The Neqati app uses FCM to send push notifications to admin users when regular users request gifts. This replaces the previous Appwrite implementation.

## Features

- **Admin Notifications**: All admin users receive push notifications when a user requests a gift
- **Device Token Management**: Automatic device token registration and refresh
- **Real-time Updates**: Notifications are sent immediately when gift requests are created
- **Secure**: Only admin users with registered device tokens receive notifications

## Architecture

### Components

1. **FCMNotificationService** (`lib/core/services/fcm_notification_service.dart`)
   - Handles FCM initialization and permissions
   - Manages device token registration and refresh
   - Sends notifications to admin users
   - Handles foreground message display

2. **GiftService** (`lib/core/services/gift_service.dart`)
   - Triggers admin notifications when gift requests are created
   - Uses FCMNotificationService through dependency injection

3. **Database Schema**
   - `users.device_token`: Stores FCM device token for each user
   - Indexed for fast admin token queries

## Setup Instructions

### 1. Firebase Project Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new Firebase project or use existing one
3. Add your Android app to the project:
   - Package name: `com.example.neqati` (or your actual package name)
   - Download `google-services.json`
   - Place it in `android/app/` directory

4. Add your iOS app to the project:
   - Bundle ID: Your iOS bundle identifier
   - Download `GoogleService-Info.plist`
   - Place it in `ios/Runner/` directory

### 2. Android Configuration

1. **Update `android/build.gradle`:**
```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

2. **Update `android/app/build.gradle`:**
```gradle
// Add at the bottom of the file
apply plugin: 'com.google.gms.google-services'
```

3. **Ensure `google-services.json` is in `android/app/`**

### 3. iOS Configuration

1. **Add `GoogleService-Info.plist` to `ios/Runner/`**

2. **Update `ios/Runner/Info.plist`:**
```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

3. **Enable Push Notifications capability in Xcode:**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner target
   - Go to "Signing & Capabilities"
   - Click "+ Capability"
   - Add "Push Notifications"
   - Add "Background Modes" and check "Remote notifications"

4. **Upload APNs Certificate to Firebase:**
   - Go to Firebase Console → Project Settings → Cloud Messaging
   - Upload your APNs authentication key or certificate

### 4. Database Migration

Run the SQL migration to add the `device_token` column:

```sql
-- Run this in your Supabase SQL editor
-- File: supabase_migrations/add_device_token_column.sql

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS device_token TEXT;

COMMENT ON COLUMN users.device_token IS 'Firebase Cloud Messaging device token for push notifications';

CREATE INDEX IF NOT EXISTS idx_users_device_token ON users(device_token) WHERE device_token IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_is_admin ON users(is_admin) WHERE is_admin = true;
```

### 5. Service Account Configuration (Required)

The app now uses FCM HTTP v1 API with OAuth2 authentication to send notifications directly from the Flutter app.

#### Step 1: Get Firebase Service Account Credentials

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click the gear icon → **Project Settings**
4. Go to **Service Accounts** tab
5. Click **Generate New Private Key**
6. Download the JSON file (keep it secure!)

#### Step 2: Configure FCMNotificationService

Open `lib/core/services/fcm_notification_service.dart` and update:

1. **Replace `_fcmProjectId`** with your Firebase project ID:
```dart
static const String _fcmProjectId = 'your-project-id';
```

2. **Replace `_serviceAccountJson`** with your service account credentials:
```dart
static const String _serviceAccountJson = '''
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "your-private-key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\\nYOUR_PRIVATE_KEY\\n-----END PRIVATE KEY-----\\n",
  "client_email": "firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com",
  "client_id": "your-client-id",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxxxx%40your-project-id.iam.gserviceaccount.com"
}
''';
```

**Important Security Notes:**
- ⚠️ Never commit service account credentials to version control
- Consider using environment variables or secure storage in production
- For production apps, implement a backend server instead

#### Step 3: Install Dependencies

Run the following command to install the required packages:

```bash
flutter pub get
```

This will install:
- `http: ^1.2.0` - For making HTTP requests to FCM API
- `googleapis_auth: ^1.6.0` - For OAuth2 authentication

#### Alternative: Backend Server (Recommended for Production)

For better security in production, consider implementing a backend server:

**Option 1: Firebase Cloud Functions**

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendNotification = functions.https.onCall(async (data, context) => {
  const { token, notification, data: notificationData } = data;
  
  const message = {
    notification: notification,
    data: notificationData,
    token: token,
  };
  
  const response = await admin.messaging().send(message);
  return { success: true, messageId: response };
});
```

**Option 2: Custom Backend (Node.js/Express)**

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

app.post('/send-notification', async (req, res) => {
  const { token, notification, data } = req.body;
  
  try {
    const response = await admin.messaging().send({
      notification: notification,
      data: data,
      token: token,
    });
    res.json({ success: true, messageId: response });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});
```

Then update `_sendNotificationToToken()` to call your backend endpoint instead of using the direct FCM API.

## How It Works

### User Flow

1. **User Login**: When a user logs in, FCM initializes and requests notification permissions
2. **Token Registration**: FCM token is obtained and saved to the `users.device_token` column
3. **Token Refresh**: If the token refreshes, it's automatically updated in the database
4. **User Logout**: Device token is cleared from the database

### Admin Notification Flow

1. **Gift Request**: User requests a gift through the app
2. **Token Fetch**: System fetches all admin device tokens from database
3. **Notification Send**: FCM sends notification to all admin devices
4. **Admin Receives**: Admin users see the notification on their devices

### Notification Payload

```dart
{
  'title': 'طلب هدية جديد',
  'body': 'أحمد طلب هدية: قسيمة شراء (100 نقطة)',
}

{
  'type': 'gift_request',
  'user_id': 'user-uuid',
  'user_name': 'أحمد',
  'gift_id': 'gift-uuid',
  'gift_name': 'قسيمة شراء',
  'gift_points': '100',
  'timestamp': '2025-01-03T22:20:19Z',
}
```

## Testing

### Test Device Token Registration

1. Run the app on a device/emulator
2. Login as any user
3. Check logs for: `🔔 FCMNotificationService: FCM Token obtained`
4. Verify token is saved in database:
```sql
SELECT id, name, device_token FROM users WHERE device_token IS NOT NULL;
```

### Test Admin Notifications

1. Ensure at least one admin user has a device token registered
2. Login as a regular user
3. Request a gift
4. Check logs for notification sending
5. Admin devices should receive the notification (once backend is set up)

## Troubleshooting

### No Token Received

- Check notification permissions are granted
- Verify Firebase configuration files are in place
- Check logs for initialization errors
- Ensure device has Google Play Services (Android)

### Notifications Not Received

- Verify admin users have `is_admin = true` in database
- Check admin device tokens are not null
- Verify backend endpoint is working (if using custom backend)
- Check FCM console for delivery status

### Token Not Saving to Database

- Check Supabase connection
- Verify `device_token` column exists in `users` table
- Check user is logged in when token is obtained
- Review logs for database errors

## Security Considerations

1. **Device Token Privacy**: Device tokens are stored in the database and should be treated as sensitive
2. **Admin Verification**: Only users with `is_admin = true` receive notifications
3. **Token Cleanup**: Tokens are cleared on logout to prevent unauthorized notifications
4. **Backend Security**: If using custom backend, ensure proper authentication and rate limiting

## Migration from Appwrite

The app has been migrated from Appwrite to FCM. Key changes:

1. **Removed**: `appwrite` package, `AppwriteService`, `appwrite_constants.dart`
2. **Added**: `firebase_messaging` package, `FCMNotificationService`
3. **Updated**: `GiftService` to use FCM instead of Appwrite
4. **Database**: Added `device_token` column to `users` table

## Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Documentation](https://firebase.flutter.dev/docs/messaging/overview)
- [FCM Admin SDK Documentation](https://firebase.google.com/docs/cloud-messaging/admin)

## Support

For issues or questions, refer to:
- Firebase Console logs
- App debug logs (search for `FCMNotificationService`)
- Supabase database logs
