const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Scheduled function to send daily reminder at 6 AM
 * Runs daily at 6:00 AM in the timezone specified
 */
exports.sendDailyReminder = functions.pubsub
  .schedule('0 6 * * *') // 6 AM every day (UTC - adjust timezone as needed)
  .timeZone('Africa/Addis_Ababa') // Ethiopia timezone (adjust to your timezone)
  .onRun(async (context) => {
    console.log('Sending daily reminder notification at 6 AM...');
    
    const message = {
      notification: {
        title: 'የዕለታዊ ንባብ ማስታወሻ',
        body: 'ዛሬ የመዝሙረ ዳዊት ንባብዎን ያስታውሱ',
      },
      data: {
        type: 'daily_reminder',
        timestamp: new Date().toISOString(),
      },
      topic: 'daily_reminder',
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'daily_reminder_channel',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    try {
      const response = await admin.messaging().send(message);
      console.log('Successfully sent daily reminder:', response);
      return null;
    } catch (error) {
      console.error('Error sending daily reminder:', error);
      throw error;
    }
  });

/**
 * Send push notification when a user receives a message
 */
exports.sendMessageNotification = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const receiverId = message.receiverId;
    const senderUsername = message.senderUsername || 'Someone';
    
    // Get receiver's FCM token and language preference
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(receiverId)
      .get();
    
    if (!userDoc.exists) {
      console.log('User document not found:', receiverId);
      return null;
    }
    
    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;
    const userLanguage = userData?.language || 'en'; // Default to English
    
    if (!fcmToken) {
      console.log('No FCM token for user:', receiverId);
      return null;
    }
    
    // Prepare notification based on language
    const isAmharic = userLanguage === 'am';
    const notificationTitle = isAmharic 
      ? `አዲስ ጥቅስ ከ ${senderUsername}`
      : `New verse from ${senderUsername}`;
    
    const verseRef = message.verseReference || 
      `Psalm ${message.chapter}${message.verseNumber ? `:${message.verseNumber}` : ''}`;
    
    const notificationBody = isAmharic
      ? verseRef
      : verseRef;
    
    const payload = {
      notification: {
        title: notificationTitle,
        body: notificationBody,
      },
      data: {
        type: 'message',
        senderId: message.senderId,
        receiverId: message.receiverId,
        chapter: message.chapter?.toString() || '',
        verseNumber: message.verseNumber?.toString() || '',
      },
      token: fcmToken,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'daily_reminder_channel',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };
    
    try {
      const response = await admin.messaging().send(payload);
      console.log('Successfully sent message notification:', response);
      return null;
    } catch (error) {
      console.error('Error sending message notification:', error);
      return null; // Don't throw - we don't want to fail message creation
    }
  });

