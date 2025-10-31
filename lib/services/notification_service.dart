// notification_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// IMPORTANT: this top-level background handler is required by firebase_messaging.
/// It MUST be a top-level or static function and annotated to avoid tree-shaking.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need plugins (eg. local notifications or tz) initialize them here.
  // For simple logging:
  print('=== Background message received: ${message.messageId} | data: ${message.data}');
  // If you need to show a local notification from background, initialize
  // FlutterLocalNotificationsPlugin and tz here.
  final FlutterLocalNotificationsPlugin local = FlutterLocalNotificationsPlugin();
  try {
    // initialize timezone & local notifications minimally for background show (optional)
    tz.initializeTimeZones();
    // Don't set local location here unless you can get device timezone synchronously.
    // Creating a simple notification channel may be necessary on Android (optional here).
  } catch (e) {
    print('Background init error: $e');
  }
}

/// Example minimal models — replace or import your real ones.
/// Ensure your real ReminderModel and MedicineModel expose fields used below.
class ReminderModel {
  final String id;
  final String medicineName;
  final String dosage;
  final TimeOfDay time;
  final bool isDueToday;
  final String timeString;

  ReminderModel({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.time,
    this.isDueToday = true,
    required this.timeString,
  });
}

class MedicineModel {
  final String id;
  final String name;
  final DateTime expiryDate;

  MedicineModel({
    required this.id,
    required this.name,
    required this.expiryDate,
  });
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isInitialized = false;

  // Android channel ids
  static const String _medicineExpiryChannelId = 'medicine_expiry';
  static const String _generalChannelId = 'general_notifications';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // initialize timezones and set local timezone properly
      await _initializeTimeZones();

      // Initialize local notifications plugin with platform settings
      final androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      final iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      final initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      // Ensure callbacks are top-level or reachable
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Forward to instance handler (this file / class)
          _onNotificationTapped(response);
        },
      );

      // Create Android notification channels (Android 8+)
      await _createAndroidNotificationChannels();

      // Request permissions (platform-specific)
      await _requestPermissions();

      // Register FCM background handler (must be top-level function)
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Init firebase messaging handlers
      await _initializeFirebaseMessaging();

      _isInitialized = true;
      print('NotificationService initialized successfully.');
    } catch (e, st) {
      print('Notification service initialization failed: $e\n$st');
    }
  }

  Future<void> _initializeTimeZones() async {
    try {
      tz.initializeTimeZones();

      // ✅ Correct class name
      final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();

      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print('✅ Timezone initialized: $timeZoneName');
    } catch (e) {
      print('⚠️ Failed to initialize timezone: $e — falling back to UTC/local defaults.');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }


  Future<void> _createAndroidNotificationChannels() async {
    final androidImpl = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl == null) {
      print('Android implementation not available (not running on Android).');
      return;
    }

    final medicineChannel = AndroidNotificationChannel(
      _medicineExpiryChannelId,
      'Medicine Expiry Alerts',
      description: 'Notifications for medicine expiry alerts',
      importance: Importance.defaultImportance,
    );

    final generalChannel = AndroidNotificationChannel(
      _generalChannelId,
      'General Notifications',
      description: 'General app notifications',
      importance: Importance.defaultImportance,
    );

    try {
      await androidImpl.createNotificationChannel(medicineChannel);
      await androidImpl.createNotificationChannel(generalChannel);
      print('Android notification channels created.');
    } catch (e) {
      print('Failed to create Android notification channels: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // iOS / Darwin permissions
      final darwinImpl =
      _localNotifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (darwinImpl != null) {
        final granted = await darwinImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('iOS/Darwin local notification permissions: $granted');
      }

      // Android POST_NOTIFICATIONS permission (Android 13+) must be requested in app runtime.
      // flutter_local_notifications does not always provide a helper for requesting the runtime permission.
      // You may use `permission_handler` or the plugin's Android-specific helper depending on version.

      // FCM permissions (APNs on iOS)
      final messagingSettings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      print('FCM permission status: ${messagingSettings.authorizationStatus}');
    } catch (e) {
      print('Permission request failed: $e');
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
      } else {
        print('FCM token is null — check permissions or network.');
      }

      // Foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message).catchError((e) => print('FG handler error: $e'));
      });

      // When a user taps a notification and app is opened/resumed
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Tapped notification (app opened): ${message.data}');
        _handleNotificationTap(message);
      });

      // Optionally handle the message which opened the app from terminated state
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        print('App opened from terminated state by message: ${initialMessage.data}');
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      print('Firebase messaging initialization failed: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      print('Foreground message received: ${message.data}');

      final id = (message.messageId ?? message.hashCode.toString()).hashCode & 0x7fffffff;

      // Show a local notification for foreground messages (optional)
      await showLocalNotification(
        id: id,
        title: message.notification?.title ?? 'MediMate AI',
        body: message.notification?.body ?? 'You have a new notification',
        payload: message.data.isNotEmpty ? message.data.toString() : null,
        details: _getDefaultNotificationDetails(),
      );
    } catch (e) {
      print('Error handling foreground message: $e');
    }
  }

  // Instance handler for message taps
  void _handleNotificationTap(RemoteMessage message) {
    try {
      print('Notification tapped (Firebase): ${message.data}');
      // TODO: navigate to appropriate screen using Navigator or pass to app-level handler
    } catch (e) {
      print('Error in notification tap handler: $e');
    }
  }

  // Local notification tap handler
  void _onNotificationTapped(NotificationResponse response) {
    try {
      print('Local notification tapped: ${response.payload}');
      // TODO: route user to correct screen based on payload
    } catch (e) {
      print('Error handling local notification tap: $e');
    }
  }

  /// Schedule a medication reminder notification
  Future<void> scheduleReminderNotification(ReminderModel reminder) async {
    try {
      if (!_isInitialized) await initialize();

      final scheduledDate = _getNextReminderDate(reminder);
      if (scheduledDate == null) return;

      // Stable positive notification id
      final notificationId = reminder.id.hashCode & 0x7fffffff;

      final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

      await _localNotifications.zonedSchedule(
        notificationId,
        'Medication Reminder',
        'Time to take ${reminder.medicineName} ${reminder.dosage}',
        tzDate,
        _getNotificationDetails(),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminder.id.toString(),
        matchDateTimeComponents: null, // set if repeating (eg. DateTimeComponents.time)
      );

      print('Scheduled reminder notification for ${reminder.medicineName} at ${reminder.timeString} (tz: $tzDate)');
    } catch (e, st) {
      print('Failed to schedule reminder notification: $e\n$st');
    }
  }

  /// Schedule expiry alert notification (7 days before)
  Future<void> scheduleExpiryAlert(MedicineModel medicine) async {
    try {
      if (!_isInitialized) await initialize();

      final notificationId = medicine.id.hashCode & 0x7fffffff;

      final alertDate = medicine.expiryDate.subtract(const Duration(days: 7));

      if (alertDate.isAfter(DateTime.now())) {
        final tzDate = tz.TZDateTime.from(alertDate, tz.local);

        await _localNotifications.zonedSchedule(
          notificationId,
          'Medicine Expiry Alert',
          '${medicine.name} expires in 7 days on ${_formatDate(medicine.expiryDate)}',
          tzDate,
          _getExpiryNotificationDetails(),
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: medicine.id.toString(),
        );

        print('Scheduled expiry alert for ${medicine.name} at $tzDate');
      } else {
        print('Expiry alert date is in the past; skipping schedule for ${medicine.name}.');
      }
    } catch (e, st) {
      print('Failed to schedule expiry alert: $e\n$st');
    }
  }

  /// Show immediate local notification
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationDetails? details,
  }) async {
    try {
      if (!_isInitialized) await initialize();
      await _localNotifications.show(id, title, body, details ?? _getDefaultNotificationDetails(), payload: payload);
    } catch (e) {
      print('Failed to show local notification: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
    } catch (e) {
      print('Failed to cancel notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      print('Failed to cancel all notifications: $e');
    }
  }

  DateTime? _getNextReminderDate(ReminderModel reminder) {
    final now = DateTime.now();

    if (reminder.isDueToday) {
      final todayReminder = DateTime(now.year, now.month, now.day, reminder.time.hour, reminder.time.minute);

      if (todayReminder.isBefore(now)) {
        // schedule for next day (safe DateTime arithmetic)
        return todayReminder.add(const Duration(days: 1));
      }
      return todayReminder;
    }

    // simplified: schedule tomorrow at reminder.time
    final tomorrow = DateTime(now.year, now.month, now.day, reminder.time.hour, reminder.time.minute).add(const Duration(days: 1));
    return tomorrow;
  }

  NotificationDetails _getNotificationDetails() {
    final androidDetails = AndroidNotificationDetails(
      _generalChannelId,
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  NotificationDetails _getExpiryNotificationDetails() {
    final androidDetails = AndroidNotificationDetails(
      _medicineExpiryChannelId,
      'Medicine Expiry Alerts',
      channelDescription: 'Notifications for medicine expiry alerts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  NotificationDetails _getDefaultNotificationDetails() {
    final androidDetails = AndroidNotificationDetails(
      _generalChannelId,
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Log-only "sendPushNotification" local stub — real push must come from your server using FCM HTTP API / admin SDK.
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    print('Push notification would be sent to user $userId: $title - $body');
    if (data != null) print('With data: $data');
  }

  /// Get FCM token for current user
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Failed to get FCM token: $e');
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Failed to subscribe to topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Failed to unsubscribe from topic: $e');
    }
  }
}
