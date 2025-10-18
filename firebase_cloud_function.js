/**
 * Firebase Cloud Functions for Neqati App - FCM Notifications
 * 
 * This file contains the backend implementation for sending FCM notifications.
 * Deploy this to Firebase Cloud Functions to enable push notifications.
 * 
 * SETUP INSTRUCTIONS:
 * ===================
 * 
 * 1. Install Firebase CLI (if not already installed):
 *    npm install -g firebase-tools
 * 
 * 2. Login to Firebase:
 *    firebase login
 * 
 * 3. Initialize Firebase Functions in your project:
 *    cd /Users/alyeldinmuhammad/Desktop/neqati
 *    firebase init functions
 *    - Select your Firebase project: neqati-b3ccf
 *    - Choose JavaScript or TypeScript (JavaScript is simpler)
 *    - Install dependencies with npm: Yes
 * 
 * 4. Copy this code to functions/index.js
 * 
 * 5. Install required dependencies:
 *    cd functions
 *    npm install firebase-admin firebase-functions
 * 
 * 6. Deploy the functions:
 *    firebase deploy --only functions
 * 
 * 7. After deployment, you'll get a URL like:
 *    https://us-central1-neqati-b3ccf.cloudfunctions.net/sendNotification
 *    Copy this URL and update it in your Flutter app (fcm_notification_service.dart)
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Send FCM notification to a single device token
 * 
 * HTTP Endpoint: POST /sendNotification
 * 
 * Request Body:
 * {
 *   "token": "device-fcm-token",
 *   "notification": {
 *     "title": "طلب هدية جديد",
 *     "body": "أحمد طلب هدية: قسيمة شراء (100 نقطة)"
 *   },
 *   "data": {
 *     "type": "gift_request",
 *     "user_id": "user-uuid",
 *     "gift_id": "gift-uuid",
 *     ...
 *   }
 * }
 * 
 * Response:
 * {
 *   "success": true,
 *   "messageId": "projects/neqati-b3ccf/messages/0:1234567890"
 * }
 */
exports.sendNotification = functions.https.onRequest(async (req, res) => {
  // Enable CORS for Flutter app
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  // Handle preflight OPTIONS request
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  // Only allow POST requests
  if (req.method !== 'POST') {
    res.status(405).json({ 
      success: false, 
      error: 'Method not allowed. Use POST.' 
    });
    return;
  }

  try {
    const { token, notification, data } = req.body;

    // Validate input
    if (!token) {
      res.status(400).json({ 
        success: false, 
        error: 'Device token is required' 
      });
      return;
    }

    if (!notification || !notification.title || !notification.body) {
      res.status(400).json({ 
        success: false, 
        error: 'Notification title and body are required' 
      });
      return;
    }

    console.log('📱 Sending notification to token:', token.substring(0, 20) + '...');
    console.log('📬 Notification:', notification);

    // Prepare the FCM message
    const message = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: data || {},
      token: token,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'neqati_notifications',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            contentAvailable: true,
          },
        },
      },
    };

    // Send the notification using Firebase Admin SDK
    const response = await admin.messaging().send(message);
    
    console.log('✅ Successfully sent notification:', response);
    
    res.status(200).json({ 
      success: true, 
      messageId: response,
    });
  } catch (error) {
    console.error('❌ Error sending notification:', error);
    
    // Handle specific FCM errors
    let errorMessage = error.message;
    if (error.code === 'messaging/invalid-registration-token' || 
        error.code === 'messaging/registration-token-not-registered') {
      errorMessage = 'Invalid or expired device token';
    }
    
    res.status(500).json({ 
      success: false, 
      error: errorMessage,
      code: error.code,
    });
  }
});

/**
 * Send FCM notification to multiple device tokens (multicast)
 * More efficient for sending to multiple admins at once
 * 
 * HTTP Endpoint: POST /sendMulticastNotification
 * 
 * Request Body:
 * {
 *   "tokens": ["token1", "token2", "token3"],
 *   "notification": {
 *     "title": "طلب هدية جديد",
 *     "body": "أحمد طلب هدية: قسيمة شراء (100 نقطة)"
 *   },
 *   "data": {
 *     "type": "gift_request",
 *     ...
 *   }
 * }
 * 
 * Response:
 * {
 *   "success": true,
 *   "successCount": 2,
 *   "failureCount": 1,
 *   "results": [...]
 * }
 */
exports.sendMulticastNotification = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ 
      success: false, 
      error: 'Method not allowed. Use POST.' 
    });
    return;
  }

  try {
    const { tokens, notification, data } = req.body;

    // Validate input
    if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
      res.status(400).json({ 
        success: false, 
        error: 'Device tokens array is required and must not be empty' 
      });
      return;
    }

    if (!notification || !notification.title || !notification.body) {
      res.status(400).json({ 
        success: false, 
        error: 'Notification title and body are required' 
      });
      return;
    }

    console.log('📱 Sending multicast notification to', tokens.length, 'devices');
    console.log('📬 Notification:', notification);

    // Prepare the multicast message
    const message = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: data || {},
      tokens: tokens,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'neqati_notifications',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            contentAvailable: true,
          },
        },
      },
    };

    // Send to multiple devices
    const response = await admin.messaging().sendMulticast(message);
    
    console.log('✅ Multicast results:', {
      success: response.successCount,
      failure: response.failureCount,
    });
    
    // Log any failures
    if (response.failureCount > 0) {
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          console.error(`❌ Failed to send to token ${idx}:`, resp.error);
        }
      });
    }
    
    res.status(200).json({ 
      success: true, 
      successCount: response.successCount,
      failureCount: response.failureCount,
      results: response.responses.map(r => ({
        success: r.success,
        messageId: r.messageId,
        error: r.error ? {
          code: r.error.code,
          message: r.error.message,
        } : null,
      })),
    });
  } catch (error) {
    console.error('❌ Error sending multicast notification:', error);
    res.status(500).json({ 
      success: false, 
      error: error.message,
      code: error.code,
    });
  }
});

/**
 * Test endpoint to verify the Cloud Function is working
 * 
 * HTTP Endpoint: GET /testNotification
 */
exports.testNotification = functions.https.onRequest((req, res) => {
  res.status(200).json({
    success: true,
    message: 'Neqati FCM Cloud Functions are working! 🎉',
    timestamp: new Date().toISOString(),
    project: 'neqati-b3ccf',
  });
});
