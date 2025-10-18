# How to Get Your FCM Server Key

## 🔑 Quick Steps

### Step 1: Open Firebase Console
Go to: https://console.firebase.google.com/

### Step 2: Select Your Project
Click on **neqati-b3ccf**

### Step 3: Go to Project Settings
Click the **⚙️ gear icon** (top left) → **Project Settings**

### Step 4: Navigate to Cloud Messaging Tab
Click on the **Cloud Messaging** tab

### Step 5: Find Server Key
Scroll down to find **Cloud Messaging API (Legacy)**

You'll see:
- **Server key**: `AAAAxxxxxx:APA91bFxxxxxx...` ← Copy this!

### Step 6: Update Flutter App

Open: `/lib/core/services/fcm_notification_service.dart`

Find line 16 and replace:
```dart
static const String _fcmServerKey = 'YOUR_FCM_SERVER_KEY_HERE';
```

With:
```dart
static const String _fcmServerKey = 'YOUR_ACTUAL_SERVER_KEY';
```

### Step 7: Rebuild and Test

```bash
flutter run
```

Then request a gift and check the logs!

## ⚠️ Important Notes

1. **Keep it secret**: Never commit the server key to public repositories
2. **Legacy API**: This uses the Legacy FCM API (still fully supported)
3. **Free plan**: Works perfectly with Firebase Spark (free) plan
4. **No Cloud Functions needed**: Sends directly from Flutter app

## 🧪 Testing

After updating the server key:
1. Login as admin on one device
2. Login as regular user on another device  
3. Request a gift as regular user
4. Admin should receive push notification! 🎉

Check logs for:
```
✅ FCMNotificationService: HTTP request successful (200 OK)
✅ FCMNotificationService: ✨ Message delivered successfully to device!
```

## 🔍 Troubleshooting

### 404 Error
- **Cause**: Legacy API not enabled or wrong server key
- **Solution**: Enable Cloud Messaging API (Legacy) in Firebase Console

### 401 Error
- **Cause**: Invalid server key
- **Solution**: Double-check you copied the correct server key

### No Server Key Visible
- **Solution**: You may need to enable Cloud Messaging API first:
  1. Firebase Console → Project Settings → Cloud Messaging
  2. Click "Enable" if you see an enable button
  3. The server key will appear

## ✅ Success Indicators

When working correctly, you'll see these logs:
```
🔔 Server key configured: YES ✅
✅ HTTP request successful (200 OK)
✅ Success count: 1
✅ Message delivered successfully to device!
```

That's it! Your FCM notifications will work without needing Cloud Functions or the paid Firebase plan! 🎊
