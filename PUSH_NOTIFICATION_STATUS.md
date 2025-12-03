# Push Notification Status Report for Chat Messages

## 📊 Current Status: **PARTIALLY IMPLEMENTED** ⚠️

### ✅ What's Working

1. **Flutter App - FCM Setup**
   - ✅ Firebase Cloud Messaging initialized in `main.dart`
   - ✅ Background notification handler configured
   - ✅ Foreground notification handler configured
   - ✅ Notification permissions requested
   - ✅ FCM token retrieved (but not sent to backend)
   - ✅ Local notifications plugin initialized

2. **Backend Infrastructure**
   - ✅ Firebase Admin SDK initialized (`firebase/firebaseAdmin.js`)
   - ✅ FCM Token model exists in database (`FcmToken` table)
   - ✅ User model has relationship to FCM tokens
   - ✅ Notification preferences model exists

3. **UI Components**
   - ✅ Notification preferences page with toggle for "Chat Notifications"
   - ✅ Preferences are saved to backend
   - ✅ Preferences are fetched from backend

### ❌ What's Missing/Broken

1. **FCM Token Not Sent to Backend**
   - ❌ FCM token is only printed to console, not sent to backend
   - ❌ Location: `lib/main.dart` line 43-45
   - ❌ TODO comment exists: "Send this token to your backend Firestore user profile document"

2. **Backend Doesn't Send Push Notifications**
   - ❌ `addMessageToChat` function doesn't send FCM notifications
   - ❌ Location: `junction-BE/controllers/chatController.js` line 48-107
   - ❌ No FCM push notification code when messages are created

3. **No FCM Token Registration Endpoint**
   - ❌ No API endpoint to register/update FCM tokens
   - ❌ No endpoint to handle token refresh

4. **Notification Preferences Not Checked**
   - ❌ Backend doesn't check `chatNotifications` preference before sending
   - ❌ Could send notifications even if user disabled them

5. **iOS Notification Configuration**
   - ⚠️ iOS notification setup may need APNs certificate (`.p8` file you downloaded)
   - ⚠️ Need to configure APNs in Firebase Console

## 🔧 Required Fixes

### Priority 1: Send FCM Token to Backend

**File:** `lib/main.dart`

```dart
// After line 44, add:
if (token != null) {
  await _sendFCMTokenToBackend(token);
}

// Add this function:
Future<void> _sendFCMTokenToBackend(String token) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');
    final userId = prefs.getString('userId');
    
    if (authToken != null && userId != null) {
      await http.post(
        Uri.parse('https://api.junctionverse.com/user/fcm-token'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': token}),
      );
    }
  } catch (e) {
    debugPrint('Failed to send FCM token: $e');
  }
}
```

### Priority 2: Create Backend FCM Token Endpoint

**File:** `junction-BE/controllers/userController.js`

```javascript
exports.registerFCMToken = async (req, res) => {
  try {
    const userId = req.user.id;
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({ message: 'FCM token is required' });
    }

    // Upsert FCM token (create or update if exists)
    await prisma.fcmToken.upsert({
      where: { token },
      update: { userId, updatedAt: new Date() },
      create: { token, userId },
    });

    res.status(200).json({ message: 'FCM token registered successfully' });
  } catch (error) {
    console.error('Error registering FCM token:', error);
    res.status(500).json({ message: 'Failed to register FCM token' });
  }
};
```

**File:** `junction-BE/routes/userRoutes.js`

```javascript
router.post('/fcm-token', authenticateToken, userController.registerFCMToken);
```

### Priority 3: Send Push Notifications on Chat Messages

**File:** `junction-BE/controllers/chatController.js`

Add after line 96 (after updating chat):

```javascript
// Send push notification to receiver
try {
  const receiver = await prisma.user.findUnique({
    where: { id: receiverId },
    include: {
      fcmTokens: true,
      notificationPrefs: true,
    },
  });

  // Check if user has chat notifications enabled
  const chatNotificationsEnabled = receiver?.notificationPrefs?.chatNotifications !== false;

  if (chatNotificationsEnabled && receiver?.fcmTokens?.length > 0) {
    const admin = require('../firebase/firebaseAdmin');
    const sender = await prisma.user.findUnique({
      where: { id: senderId },
      select: { fullName: true },
    });

    const message = {
      notification: {
        title: sender?.fullName || 'New Message',
        body: messageText || 'You received a new message',
      },
      data: {
        type: 'chat',
        chatId: chatId,
        senderId: senderId,
      },
    };

    // Send to all user's FCM tokens
    const tokens = receiver.fcmTokens.map(ft => ft.token);
    await admin.messaging().sendEachForMulticast({
      tokens,
      ...message,
    });
  }
} catch (notificationError) {
  console.error('Failed to send push notification:', notificationError);
  // Don't fail the message send if notification fails
}
```

### Priority 4: Handle Token Refresh

**File:** `lib/main.dart`

Add after line 60:

```dart
// Handle token refresh
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  print('FCM Token refreshed: $newToken');
  _sendFCMTokenToBackend(newToken);
});
```

## 📱 Testing Checklist

- [ ] FCM token is sent to backend after login
- [ ] FCM token is updated when refreshed
- [ ] Push notification received when chat message sent (app in background)
- [ ] Push notification received when chat message sent (app in foreground)
- [ ] Push notification NOT sent when user disabled chat notifications
- [ ] Notification opens correct chat when tapped
- [ ] Works on both Android and iOS

## 🔍 Additional Notes

1. **APNs Certificate**: The `.p8` file you downloaded needs to be uploaded to Firebase Console:
   - Go to Firebase Console → Project Settings → Cloud Messaging
   - Upload `AuthKey_FXB4LC93Y3.p8`
   - Enter Key ID: `FXB4LC93Y3`
   - Enter Team ID: (from Apple Developer account)

2. **Notification Payload**: Consider adding more data to notification payload:
   - Chat ID for deep linking
   - Message type (text/image/price quote)
   - Product ID if applicable

3. **Error Handling**: Add proper error handling for:
   - Invalid FCM tokens
   - Network failures
   - User not found scenarios

