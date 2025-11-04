import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../services/localization_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions (Android 13+)
    await _requestPermissions();

    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    // Request Android 13+ notification permissions
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    // Request iOS permissions (handled automatically by the plugin)
    // iOS permissions are requested when initialize() is called
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap if needed
    // You can navigate to a specific page here
  }

  // Schedule daily reminder at 6 AM
  Future<void> scheduleDailyReminder() async {
    if (!_initialized) {
      await initialize();
    }

    // Cancel any existing reminder
    await _notifications.cancel(1);

    // Get current timezone
    final location = tz.local;

    // Schedule notification for 6 AM every day
    await _notifications.zonedSchedule(
      1, // Notification ID
      LocalizationService.instance.currentLanguage == 'am' 
          ? 'የዕለታዊ ንባብ ማስታወሻ'
          : 'Daily Reading Reminder',
      LocalizationService.instance.currentLanguage == 'am'
          ? 'ዛሬ የመዝሙረ ዳዊት ንባብዎን ያስታውሱ'
          : 'Remember to read your daily Psalms today',
      _getNext6AM(location),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reading Reminder',
          channelDescription: 'Daily reminder to read Psalms',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at the same time
    );
  }

  // Get the next 6 AM time
  tz.TZDateTime _getNext6AM(tz.Location location) {
    final now = tz.TZDateTime.now(location);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      6, // 6 AM
      00,
    );

    // If 6 AM has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Cancel the daily reminder
  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(1);
  }

  // Update notification text based on current language
  Future<void> updateNotificationLanguage() async {
    await cancelDailyReminder();
    await scheduleDailyReminder();
  }
}

