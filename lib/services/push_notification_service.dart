import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/localization_service.dart';

// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages here
  print('Handling background message: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _fcmToken;

  // Get FCM token
  String? get fcmToken => _fcmToken;

  // Initialize push notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request notification permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('User granted provisional notification permission');
      } else {
        print('User declined or has not accepted notification permission');
        // Continue initialization even if permission not granted
        // User can grant permission later
      }
    } catch (e) {
      print('Error requesting notification permission: $e');
      // Continue initialization even if permission request fails
    }

    // Initialize local notifications for displaying notifications when app is in foreground
    try {
      await _initializeLocalNotifications();
    } catch (e) {
      print('Error initializing local notifications: $e');
      // Continue even if local notifications fail
    }

    // Get FCM token
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('FCM Token: $_fcmToken');
      
      // Save token to Firestore if user is logged in
      if (_fcmToken != null && FirebaseAuth.instance.currentUser != null) {
        await _saveTokenToFirestore(_fcmToken!);
      }
    } catch (e) {
      print('Error getting FCM token: $e');
      // Continue even if token retrieval fails
    }

    // Listen for token refresh
    try {
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('FCM Token refreshed: $newToken');
        _saveTokenToFirestore(newToken).catchError((e) {
          print('Error saving refreshed token: $e');
        });
      });
    } catch (e) {
      print('Error setting up token refresh listener: $e');
    }

    // Set up message handlers
    try {
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      // Handle notification when app is opened from terminated state
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      print('Error setting up message handlers: $e');
      // Continue even if message handlers fail
    }

    _initialized = true;
  }

  Future<void> _initializeLocalNotifications() async {
    // Android initialization settings
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    // Request Android 13+ permissions
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  // Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    
    // Show local notification when app is in foreground
    _showLocalNotification(message);
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    // Navigate to appropriate screen if needed
    // You can use a navigator key or notification data to route
  }

  // Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final isAmharic = LocalizationService.instance.currentLanguage == 'am';
    
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title ?? (isAmharic ? 'የዕለታዊ ንባብ ማስታወሻ' : 'Daily Reading Reminder'),
        notification.body ?? (isAmharic ? 'ዛሬ የመዝሙረ ዳዊት ንባብዎን ያስታውሱ' : 'Remember to read your daily Psalms today'),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_channel',
            'Daily Reading Reminder',
            channelDescription: 'Daily reminder to read Psalms',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  // Save FCM token to Firestore for this user
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Also save current language preference
        final currentLanguage = LocalizationService.instance.currentLanguage;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'language': currentLanguage, // Save language preference
        });
        print('FCM token and language saved to Firestore for user: ${user.uid}');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }
  
  // Save FCM token when user logs in
  Future<void> saveTokenForCurrentUser() async {
    if (_fcmToken != null) {
      await _saveTokenToFirestore(_fcmToken!);
    }
  }

  // Subscribe to a topic (for broadcasting to all users)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
      // Don't throw - allow app to continue
    }
  }

  // Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  // Delete FCM token (when user logs out)
  Future<void> deleteToken() async {
    await _firebaseMessaging.deleteToken();
    _fcmToken = null;
    print('FCM token deleted');
  }
}

