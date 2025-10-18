# Firebase Cloud Functions Deployment Guide for Neqati App

This guide will help you deploy the Firebase Cloud Function to enable FCM push notifications in your Neqati app.

## 📋 Prerequisites

- Node.js installed (v16 or later recommended)
- Firebase CLI installed
- Firebase project: `neqati-b3ccf`

## 🚀 Step-by-Step Deployment

### Step 1: Install Firebase CLI

If you haven't installed Firebase CLI yet:

```bash
npm install -g firebase-tools
```

Verify installation:
```bash
firebase --version
```

### Step 2: Login to Firebase

```bash
firebase login
```

This will open a browser window for you to authenticate with your Google account.

### Step 3: Initialize Firebase Functions

Navigate to your project directory:

```bash
cd /Users/alyeldinmuhammad/Desktop/neqati
```

Initialize Firebase Functions:

```bash
firebase init functions
```

When prompted:
1. **Select your Firebase project**: Choose `neqati-b3ccf`
2. **Language**: Select `JavaScript` (easier) or `TypeScript` (if you prefer)
3. **ESLint**: Choose `No` (optional)
4. **Install dependencies**: Choose `Yes`

This will create a `functions` directory with the following structure:
```
neqati/
├── functions/
│   ├── index.js          # Your Cloud Functions code goes here
│   ├── package.json      # Dependencies
│   └── node_modules/     # Installed packages
```

### Step 4: Copy the Cloud Function Code

Copy the content from `firebase_cloud_function.js` to `functions/index.js`:

```bash
cp firebase_cloud_function.js functions/index.js
```

Or manually copy the code from `firebase_cloud_function.js` into `functions/index.js`.

### Step 5: Install Dependencies

The required dependencies should already be installed, but verify:

```bash
cd functions
npm install firebase-admin firebase-functions
cd ..
```

### Step 6: Deploy the Cloud Functions

Deploy all functions to Firebase:

```bash
firebase deploy --only functions
```

This will take a few minutes. You'll see output like:

```
✔  functions: Finished running predeploy script.
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
i  functions: ensuring required API cloudbuild.googleapis.com is enabled...
✔  functions: required API cloudfunctions.googleapis.com is enabled
✔  functions: required API cloudbuild.googleapis.com is enabled
i  functions: preparing functions directory for uploading...
i  functions: packaged functions (XX.XX KB) for uploading
✔  functions: functions folder uploaded successfully
i  functions: creating Node.js 16 function sendNotification(us-central1)...
i  functions: creating Node.js 16 function sendMulticastNotification(us-central1)...
i  functions: creating Node.js 16 function testNotification(us-central1)...
✔  functions[sendNotification(us-central1)]: Successful create operation.
✔  functions[sendMulticastNotification(us-central1)]: Successful create operation.
✔  functions[testNotification(us-central1)]: Successful create operation.

✔  Deploy complete!

Function URL (sendNotification): https://us-central1-neqati-b3ccf.cloudfunctions.net/sendNotification
Function URL (sendMulticastNotification): https://us-central1-neqati-b3ccf.cloudfunctions.net/sendMulticastNotification
Function URL (testNotification): https://us-central1-neqati-b3ccf.cloudfunctions.net/testNotification
```

**IMPORTANT**: Copy the Function URLs - you'll need them in the next step!

### Step 7: Update Flutter App with Cloud Function URLs

Open `lib/core/services/fcm_notification_service.dart` and update the URLs:

```dart
// Replace these URLs with your actual Cloud Function URLs from Step 6
static const String _cloudFunctionUrl = 
    'https://us-central1-neqati-b3ccf.cloudfunctions.net/sendNotification';

static const String _cloudFunctionMulticastUrl = 
    'https://us-central1-neqati-b3ccf.cloudfunctions.net/sendMulticastNotification';
```

### Step 8: Test the Cloud Function

#### Option 1: Test via Browser

Open the test endpoint in your browser:
```
https://us-central1-neqati-b3ccf.cloudfunctions.net/testNotification
```

You should see:
```json
{
  "success": true,
  "message": "Neqati FCM Cloud Functions are working! 🎉",
  "timestamp": "2025-01-04T12:30:00.000Z",
  "project": "neqati-b3ccf"
}
```

#### Option 2: Test via Flutter App

1. Build and run your Flutter app
2. Login as a regular user
3. Request a gift
4. Check if the admin receives a push notification

### Step 9: Monitor Cloud Function Logs

View real-time logs:

```bash
firebase functions:log
```

Or view logs in Firebase Console:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `neqati-b3ccf`
3. Click on **Functions** in the left menu
4. Click on a function to see its logs

## 🔧 Troubleshooting

### Issue: "Permission denied" error

**Solution**: Make sure you're logged in with the correct Google account:
```bash
firebase logout
firebase login
```

### Issue: "Billing account not configured"

**Solution**: Firebase Cloud Functions require the Blaze (pay-as-you-go) plan:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click on **Upgrade** in the left menu
4. Choose the **Blaze** plan (free tier includes generous limits)

### Issue: "Function deployment failed"

**Solution**: Check the error message and ensure:
- Node.js version is compatible (v16 or later)
- All dependencies are installed: `cd functions && npm install`
- No syntax errors in `functions/index.js`

### Issue: Notifications not received on device

**Checklist**:
1. ✅ Cloud Function deployed successfully
2. ✅ Flutter app updated with correct Cloud Function URL
3. ✅ Device has FCM token saved in database
4. ✅ User is an admin (check `is_admin` field in database)
5. ✅ App has notification permissions granted
6. ✅ Check Cloud Function logs for errors

## 📊 Monitoring & Analytics

### View Function Usage

Firebase Console → Functions → Click on function name → Usage tab

### View Function Logs

```bash
# Real-time logs
firebase functions:log

# Filter by function
firebase functions:log --only sendNotification

# Last 100 lines
firebase functions:log --lines 100
```

### Check Notification Delivery

Firebase Console → Cloud Messaging → Reports

## 💰 Pricing

Firebase Cloud Functions pricing (Blaze plan):
- **Free tier**: 2 million invocations/month
- **After free tier**: $0.40 per million invocations
- **Network egress**: First 5GB free, then $0.12/GB

For the Neqati app with moderate usage:
- Estimated cost: **$0-5/month** (likely $0 with free tier)

## 🔄 Updating Cloud Functions

When you make changes to the Cloud Function code:

1. Edit `functions/index.js`
2. Deploy the updated function:
   ```bash
   firebase deploy --only functions
   ```
3. No need to update the Flutter app (URLs remain the same)

## 🔐 Security Best Practices

1. **Enable CORS**: Already configured in the Cloud Function
2. **Add authentication** (optional): Add API key validation if needed
3. **Rate limiting**: Consider implementing rate limits for production
4. **Monitor logs**: Regularly check for suspicious activity

## 📱 Testing Notifications

### Test with a single device:

```bash
curl -X POST https://us-central1-neqati-b3ccf.cloudfunctions.net/sendNotification \
  -H "Content-Type: application/json" \
  -d '{
    "token": "YOUR_DEVICE_TOKEN",
    "notification": {
      "title": "Test Notification",
      "body": "This is a test from Cloud Functions"
    },
    "data": {
      "type": "test"
    }
  }'
```

### Test with multiple devices:

```bash
curl -X POST https://us-central1-neqati-b3ccf.cloudfunctions.net/sendMulticastNotification \
  -H "Content-Type: application/json" \
  -d '{
    "tokens": ["TOKEN1", "TOKEN2"],
    "notification": {
      "title": "Test Notification",
      "body": "This is a multicast test"
    },
    "data": {
      "type": "test"
    }
  }'
```

## ✅ Verification Checklist

After deployment, verify:

- [ ] Cloud Functions deployed successfully
- [ ] Test endpoint returns success response
- [ ] Flutter app updated with correct URLs
- [ ] Flutter app builds without errors
- [ ] Admin user has device token in database
- [ ] Gift request triggers notification to admin
- [ ] Admin receives push notification on device
- [ ] Notification displays correct title and body
- [ ] Cloud Function logs show successful sends

## 🎉 Success!

Once all steps are complete, your Neqati app will send real push notifications to admin users when regular users request gifts!

## 📚 Additional Resources

- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [FCM Admin SDK Documentation](https://firebase.google.com/docs/cloud-messaging/admin)
- [Firebase Console](https://console.firebase.google.com/)

## 🆘 Need Help?

If you encounter issues:
1. Check Cloud Function logs: `firebase functions:log`
2. Check Flutter app logs for errors
3. Verify all URLs are correct
4. Ensure billing is enabled (Blaze plan)
5. Check Firebase Console for any alerts
