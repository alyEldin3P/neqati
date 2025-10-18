# Migration Summary: Appwrite → Firebase Cloud Messaging (FCM)

## Overview

Successfully migrated the Neqati app from Appwrite push notifications to Firebase Cloud Messaging (FCM) for sending admin notifications when users request gifts.

## Changes Made

### 1. Dependencies Updated

**Removed:**
- `appwrite: 17.0.0`

**Added:**
- `firebase_messaging: ^15.1.5`
- `firebase_core: ^3.8.1`

### 2. New Files Created

- **`lib/core/services/fcm_notification_service.dart`**
  - Handles FCM initialization and permissions
  - Manages device token registration and refresh
  - Sends notifications to all admin users
  - Handles foreground message display

- **`supabase_migrations/add_device_token_column.sql`**
  - SQL migration to add `device_token` column to `users` table
  - Includes indexes for performance optimization

- **`FCM_SETUP_GUIDE.md`**
  - Comprehensive setup guide for Firebase and FCM
  - Instructions for Android and iOS configuration
  - Backend setup options (Cloud Functions or custom server)
  - Testing and troubleshooting guide

### 3. Files Deleted

- `lib/core/services/appwrite_service.dart`
- `lib/core/const/appwrite_constants.dart`
- `APPWRITE_SETUP_GUIDE.md`
- `APPWRITE_QUICK_START.md`
- `NOTIFICATION_DEBUG_LOGS.md`

### 4. Files Modified

**`pubspec.yaml`**
- Removed Appwrite dependency
- Added Firebase Messaging and Core dependencies

**`lib/features/auth/model/user.dart`**
- Added `deviceToken` field to AppUser model
- Updated `fromSupabase()`, `toSupabase()`, and `copyWith()` methods

**`lib/core/services/gift_service.dart`**
- Replaced Appwrite notification calls with FCM
- Updated to use `FCMNotificationService` through dependency injection
- Changed notification method from `sendGiftRequestNotificationToAdmin` to `sendGiftRequestNotificationToAdmins`

**`lib/core/services/dependency_injector.dart`**
- Removed AppwriteService registration
- Added FCMNotificationService registration and initialization
- Updated service getters

**`android/app/src/main/AndroidManifest.xml`**
- Removed Appwrite callback activity configuration

## Database Changes

### New Column: `users.device_token`

```sql
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS device_token TEXT;
```

**Purpose:** Stores Firebase Cloud Messaging device token for each user

**Indexes:**
- `idx_users_device_token`: For fast token lookups
- `idx_users_is_admin`: For fast admin user queries

## How It Works

### Device Token Management

1. **On App Launch**: FCM initializes and requests notification permissions
2. **Token Obtained**: Device token is saved to `users.device_token` in database
3. **Token Refresh**: Automatic updates when token changes
4. **On Logout**: Token is cleared from database

### Admin Notification Flow

1. **User Requests Gift**: Gift request is created in database
2. **Fetch Admin Tokens**: Query all admin users' device tokens
3. **Send Notifications**: FCM sends push notification to all admin devices
4. **Admin Receives**: Notification appears on admin devices with gift request details

### Notification Payload

**Title:** "طلب هدية جديد"
**Body:** "[User Name] طلب هدية: [Gift Name] ([Points] نقطة)"

**Data:**
- `type`: "gift_request"
- `user_id`: User UUID
- `user_name`: User's name
- `gift_id`: Gift UUID
- `gift_name`: Gift name
- `gift_points`: Required points
- `timestamp`: ISO 8601 timestamp

## Next Steps Required

### 1. Run Database Migration

Execute the SQL migration in your Supabase SQL editor:

```bash
# File: supabase_migrations/add_device_token_column.sql
```

### 2. Firebase Project Setup

1. Create/configure Firebase project
2. Add Android app and download `google-services.json`
3. Add iOS app and download `GoogleService-Info.plist`
4. Configure Android and iOS projects (see FCM_SETUP_GUIDE.md)

### 3. Backend Implementation (IMPORTANT)

The current implementation **logs notification details but doesn't send them**. You must implement one of these options:

**Option A: Firebase Cloud Functions (Recommended)**
- Create a Cloud Function to send notifications using FCM Admin SDK
- Update `FCMNotificationService._sendNotificationToToken()` to call the function

**Option B: Custom Backend Server**
- Create an API endpoint that uses FCM Admin SDK
- Update `FCMNotificationService._sendNotificationToToken()` to call your endpoint

See `FCM_SETUP_GUIDE.md` for detailed implementation examples.

### 4. Testing

1. **Test Token Registration:**
   - Login as any user
   - Check logs for successful token registration
   - Verify token in database

2. **Test Admin Notifications:**
   - Ensure at least one admin has a device token
   - Request a gift as regular user
   - Check logs for notification sending
   - Verify admin receives notification (after backend setup)

## Benefits of FCM over Appwrite

1. **Industry Standard**: FCM is the standard for mobile push notifications
2. **Better Integration**: Native Firebase integration with Flutter
3. **Reliability**: Google's infrastructure for message delivery
4. **Free Tier**: Generous free tier for push notifications
5. **Rich Features**: Support for topics, groups, and advanced targeting
6. **Analytics**: Built-in delivery and engagement analytics

## Security Considerations

- Device tokens are stored securely in Supabase
- Only admin users (`is_admin = true`) receive gift request notifications
- Tokens are cleared on logout to prevent unauthorized access
- Backend endpoint should implement proper authentication and rate limiting

## Rollback Plan

If you need to rollback to Appwrite:

1. Restore deleted files from git history
2. Revert `pubspec.yaml` changes
3. Revert modified service files
4. Run `flutter pub get`
5. Optionally drop `device_token` column from database

## Support & Documentation

- **Setup Guide**: `FCM_SETUP_GUIDE.md`
- **Firebase Docs**: https://firebase.google.com/docs/cloud-messaging
- **FlutterFire Docs**: https://firebase.flutter.dev/docs/messaging/overview

## Status

✅ **Migration Complete** - Code changes are done
⚠️ **Action Required** - Firebase setup and backend implementation needed

---

**Migration Date**: January 3, 2025
**Migrated By**: Development Team
**App Version**: 1.0.0+1
