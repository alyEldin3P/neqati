# FCM Quick Start Checklist

Quick checklist to get Firebase Cloud Messaging working in the Neqati app.

## ✅ Completed (Already Done)

- [x] Remove Appwrite dependencies
- [x] Add Firebase Messaging dependencies
- [x] Create FCMNotificationService
- [x] Update GiftService to use FCM
- [x] Add device_token field to user model
- [x] Update dependency injection
- [x] Remove Appwrite configuration from AndroidManifest

## 🔲 Required Steps (You Need to Do)

### 1. Database Setup

- [ ] Run the SQL migration in Supabase:
  ```sql
  -- Copy and paste from: supabase_migrations/add_device_token_column.sql
  ```

### 2. Firebase Project Setup

- [ ] Go to [Firebase Console](https://console.firebase.google.com/)
- [ ] Create new project or select existing one
- [ ] Add Android app:
  - [ ] Package name: `com.example.neqati` (check `android/app/build.gradle`)
  - [ ] Download `google-services.json`
  - [ ] Place in `android/app/` directory
- [ ] Add iOS app:
  - [ ] Bundle ID: (check `ios/Runner.xcodeproj`)
  - [ ] Download `GoogleService-Info.plist`
  - [ ] Place in `ios/Runner/` directory

### 3. Android Configuration

- [ ] Edit `android/build.gradle`:
  ```gradle
  buildscript {
      dependencies {
          classpath 'com.google.gms:google-services:4.4.0'  // Add this
      }
  }
  ```

- [ ] Edit `android/app/build.gradle`:
  ```gradle
  // Add at the bottom
  apply plugin: 'com.google.gms.google-services'
  ```

- [ ] Verify `google-services.json` is in `android/app/`

### 4. iOS Configuration

- [ ] Add `GoogleService-Info.plist` to `ios/Runner/` in Xcode
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Add "Push Notifications" capability
- [ ] Add "Background Modes" capability → Check "Remote notifications"
- [ ] Upload APNs certificate to Firebase Console

### 5. Backend Setup (CRITICAL - Notifications won't work without this!)

Choose ONE option:

#### Option A: Firebase Cloud Functions (Recommended)

- [ ] Install Firebase CLI: `npm install -g firebase-tools`
- [ ] Initialize Functions: `firebase init functions`
- [ ] Create function (see `FCM_SETUP_GUIDE.md` for code)
- [ ] Deploy: `firebase deploy --only functions`
- [ ] Update `FCMNotificationService._sendNotificationToToken()` to call function

#### Option B: Custom Backend

- [ ] Create API endpoint with FCM Admin SDK
- [ ] Deploy to your server
- [ ] Update `FCMNotificationService._sendNotificationToToken()` to call endpoint

### 6. Testing

- [ ] Run app: `flutter run`
- [ ] Login as any user
- [ ] Check logs for: `🔔 FCMNotificationService: FCM Token obtained`
- [ ] Verify token in database:
  ```sql
  SELECT id, name, device_token FROM users WHERE device_token IS NOT NULL;
  ```
- [ ] Make at least one user admin:
  ```sql
  UPDATE users SET is_admin = true WHERE id = 'user-id';
  ```
- [ ] Login as regular user and request a gift
- [ ] Admin should receive notification

## 📝 Important Notes

1. **Backend is Required**: The app currently logs notifications but doesn't send them. You MUST implement a backend (Cloud Functions or custom server) to actually send notifications.

2. **Test on Real Devices**: FCM doesn't work on iOS simulators. Use real devices for testing.

3. **Permissions**: Users must grant notification permissions when prompted.

4. **Admin Setup**: At least one admin user must have a device token registered to receive notifications.

## 🆘 Quick Troubleshooting

**No token received?**
- Check notification permissions
- Verify Firebase config files are in place
- Check logs for errors

**Notifications not sending?**
- Verify backend is implemented and working
- Check admin users have `is_admin = true`
- Verify admin device tokens are not null

**Build errors?**
- Run `flutter clean && flutter pub get`
- Verify `google-services.json` and `GoogleService-Info.plist` are in correct locations
- Check Firebase configuration in build files

## 📚 Full Documentation

For detailed instructions, see:
- **Setup Guide**: `FCM_SETUP_GUIDE.md`
- **Migration Summary**: `MIGRATION_SUMMARY.md`

## ⏱️ Estimated Time

- Database migration: 5 minutes
- Firebase setup: 15-20 minutes
- Android configuration: 10 minutes
- iOS configuration: 15-20 minutes
- Backend setup: 30-60 minutes
- Testing: 15 minutes

**Total: ~2 hours**

---

Good luck! 🚀
