/**
 * Firebase Cloud Functions for Push Notifications
 * 
 * This function triggers when a new message is written to Firestore
 * and sends a push notification to the receiver.
 * 
 * Setup:
 * 1. Install Firebase CLI: npm install -g firebase-tools
 * 2. Login: firebase login
 * 3. Initialize: firebase init functions
 * 4. Deploy: firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin (use your existing service account)
admin.initializeApp();

/**
 * Triggered when a new message is added to Firestore
 * Using Firebase Functions v1 API (compatible with Node.js 20)
 */
exports.sendChatNotification = functions.firestore
  .document('messages/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const { chatId } = context.params;
    
    console.log('📱 [FCM Cloud Function] New message detected');
    console.log('📱 [FCM Cloud Function] Chat ID:', chatId);
    console.log('📱 [FCM Cloud Function] Message:', message);

    const senderId = message.senderId;
    const receiverId = message.receiverId;
    const messageText = message.message || '';
    const messageType = message.messageType || 'text';

    if (!senderId || !receiverId) {
      console.log('📱 [FCM Cloud Function] ❌ Missing senderId or receiverId');
      return null;
    }

    try {
      // Get receiver's FCM tokens from Firestore
      const receiverDoc = await admin.firestore()
        .collection('users')
        .doc(receiverId)
        .get();

      if (!receiverDoc.exists) {
        console.log('📱 [FCM Cloud Function] ❌ Receiver not found:', receiverId);
        return null;
      }

      const receiverData = receiverDoc.data();
      const fcmTokens = receiverData.fcmTokens || [];
      
      if (fcmTokens.length === 0) {
        console.log('📱 [FCM Cloud Function] ⚠️ No FCM tokens for receiver:', receiverId);
        return null;
      }

      // Check notification preferences
      const notificationPrefs = receiverData.notificationPrefs || {};
      const chatNotificationsEnabled = notificationPrefs.chatNotifications !== false;

      if (!chatNotificationsEnabled) {
        console.log('📱 [FCM Cloud Function] ⚠️ Chat notifications disabled for user:', receiverId);
        return null;
      }

      // Get sender information
      const senderDoc = await admin.firestore()
        .collection('users')
        .doc(senderId)
        .get();

      const senderData = senderDoc.exists ? senderDoc.data() : {};
      const senderName = senderData.fullName || senderData.name || 'Someone';

      // Prepare notification
      const notificationBody = messageType === 'image' 
        ? '📷 Sent a photo' 
        : (messageText || 'Sent a message');

      const payload = {
        notification: {
          title: senderName,
          body: notificationBody,
        },
        data: {
          type: 'chat',
          chatId: chatId,
          senderId: senderId,
          messageId: context.params.messageId,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'chat',
            sound: 'default',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            tag: 'chat',
          },
        },
        apns: {
          headers: {
            'apns-priority': '10',
            'apns-push-type': 'alert',
          },
          payload: {
            aps: {
              alert: {
                title: senderName,
                body: notificationBody,
              },
              sound: 'default',
              badge: 1,
              'content-available': 1,
            },
          },
        },
      };

      // Send to all tokens
      if (fcmTokens.length === 1) {
        const response = await admin.messaging().send({
          token: fcmTokens[0],
          ...payload,
        });
        console.log('📱 [FCM Cloud Function] ✅ Notification sent:', response);
      } else {
        const response = await admin.messaging().sendEachForMulticast({
          tokens: fcmTokens,
          ...payload,
        });
        console.log('📱 [FCM Cloud Function] ✅ Notifications sent:', {
          success: response.successCount,
          failure: response.failureCount,
        });
      }

      return null;
    } catch (error) {
      console.error('📱 [FCM Cloud Function] ❌ Error:', error);
      return null;
    }
  });

