# Push Notification Setup Guide

This guide explains how to set up and use Firebase Cloud Messaging (FCM) push notifications in your app.

## Overview

The app uses Firebase Cloud Messaging (FCM) for push notifications. When users receive messages (verse shares), they will receive push notifications.

## Features Implemented

1. **FCM Token Management**: Automatically saves FCM tokens to Firestore for each user
2. **Topic Subscriptions**: Users are subscribed to `daily_reminder` topic for broadcast notifications
3. **Foreground Notifications**: Shows local notifications when app is in foreground
4. **Background Notifications**: Handles notifications when app is in background
5. **Notification Permissions**: Requests appropriate permissions on Android and iOS

## Setup Instructions

### 1. Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** > **Cloud Messaging**
4. Ensure you have:
   - **Server Key** (for sending notifications via REST API)
   - **Sender ID** (automatically configured in your app)

### 2. Android Configuration

The Android configuration is already set up in `android/app/src/main/AndroidManifest.xml`:
- Notification permissions are declared
- Boot receiver is configured for restarting notifications
- `android:exported` attributes are set correctly

### 3. iOS Configuration (if needed)

For iOS, you'll need to:
1. Enable Push Notifications capability in Xcode
2. Upload your APNs certificate or key to Firebase Console
3. Go to **Project Settings** > **Cloud Messaging** > **Apple app configuration**

### 4. Testing Push Notifications

#### Option 1: Using Firebase Console (Easiest)

1. Go to Firebase Console > **Cloud Messaging**
2. Click **Send your first message**
3. Enter notification title and text
4. Select **Target**: Choose **Topic** and enter `daily_reminder`
5. Click **Review** > **Publish**

#### Option 2: Using FCM REST API

You can send notifications programmatically using the FCM REST API. Here's an example:

```bash
curl -X POST https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "topic": "daily_reminder",
      "notification": {
        "title": "Daily Reading Reminder",
        "body": "Remember to read your daily Psalms today"
      },
      "data": {
        "type": "daily_reminder"
      }
    }
  }'
```

#### Option 3: Using Firebase Cloud Functions (Recommended for Production)

Create a Cloud Function to send push notifications when messages are sent:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendMessageNotification = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const receiverId = message.receiverId;
    
    // Get receiver's FCM token
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(receiverId)
      .get();
    
    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) return null;
    
    // Send notification
    const payload = {
      notification: {
        title: `New verse from ${message.senderUsername}`,
        body: message.verseReference || `Psalm ${message.chapter}${message.verseNumber != null ? ':${message.verseNumber}' : ''}`,
      },
      data: {
        type: 'message',
        senderId: message.senderId,
        receiverId: message.receiverId,
        chapter: message.chapter.toString(),
        verseNumber: message.verseNumber?.toString() || '',
      },
      token: fcmToken,
    };
    
    return admin.messaging().send(payload);
  });
```

### 5. Sending Notifications for Messages

To send push notifications when users receive messages, you have two options:

#### Option A: Cloud Functions (Recommended)

Create a Cloud Function that triggers when a new message is created in Firestore. See the example above.

#### Option B: Client-side (Not Recommended for Production)

You can send notifications from the client using the FCM REST API, but this requires:
- Storing your server key securely (not recommended)
- Managing authentication tokens

**Note**: For production, always use Cloud Functions or a backend server to send push notifications.

## How It Works

1. **Initialization**: When the app starts, `PushNotificationService` initializes and:
   - Requests notification permissions
   - Gets the FCM token
   - Saves the token to Firestore under `users/{userId}/fcmToken`
   - Subscribes the user to the `daily_reminder` topic

2. **Token Refresh**: If the FCM token changes, it's automatically updated in Firestore

3. **Receiving Notifications**:
   - **Foreground**: Shows a local notification using `flutter_local_notifications`
   - **Background**: Handled by `firebaseMessagingBackgroundHandler`
   - **Terminated**: Handled when app is opened from notification

4. **Sending Notifications**:
   - **Topic-based**: Send to all users subscribed to `daily_reminder` topic
   - **Token-based**: Send to specific users using their FCM token from Firestore

## Testing

1. **Test Token Registration**:
   - Open the app and log in
   - Check the console for "FCM Token: ..."
   - Verify the token is saved in Firestore: `users/{userId}/fcmToken`

2. **Test Topic Subscription**:
   - Send a test notification to `daily_reminder` topic from Firebase Console
   - You should receive the notification

3. **Test Message Notifications**:
   - Send a message from one user to another
   - If Cloud Functions are set up, the receiver should get a push notification

## Troubleshooting

### Notifications not received on Android
- Check that notification permissions are granted
- Verify `google-services.json` is correctly configured
- Check Android logs for FCM errors

### Notifications not received on iOS
- Verify APNs certificate/key is uploaded to Firebase
- Check that Push Notifications capability is enabled in Xcode
- Ensure device is registered for remote notifications

### Token not saved to Firestore
- Check Firestore security rules allow writes to `users/{userId}`
- Verify user is authenticated when token is saved

## Next Steps

1. **Set up Cloud Functions** for sending message notifications (recommended)
2. **Configure daily reminder notifications** via Cloud Functions or scheduled tasks
3. **Customize notification appearance** using notification channels (Android)
4. **Add notification actions** (reply, mark as read, etc.)

## Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging Plugin](https://pub.dev/packages/firebase_messaging)
- [Cloud Functions Documentation](https://firebase.google.com/docs/functions)

