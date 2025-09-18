import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '/models/reminder_model.dart';
import '/models/medicine_model.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    tz.initializeTimeZones();

    try {
      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions
      await _requestPermissions();

      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();

      _isInitialized = true;
    } catch (e) {
      print('Notification service initialization failed: $e');
    }
  }

  Future<void> _requestPermissions() async {
    // Request local notification permissions
    final androidGranted = await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    final iosGranted = await _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Request Firebase messaging permissions
    final messagingSettings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('Notification permissions - Android: $androidGranted, iOS: $iosGranted, FCM: ${messagingSettings.authorizationStatus}');
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    } catch (e) {
      print('Firebase messaging initialization failed: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message received: ${message.data}');
    
    // Show local notification for foreground messages
    await showLocalNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'MediMate AI',
      body: message.notification?.body ?? 'You have a new notification',
      payload: message.data.toString(),
    );
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Background message received: ${message.data}');
    // Handle background message processing here
  }

  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    // Navigate to appropriate screen based on message data
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    // Handle local notification tap
  }

  /// Schedule a medication reminder notification
  Future<void> scheduleReminderNotification(ReminderModel reminder) async {
    try {
      if (!_isInitialized) await initialize();

      final scheduledDate = _getNextReminderDate(reminder);
      if (scheduledDate == null) return;

      final notificationId = reminder.id.hashCode;

      await _localNotifications.zonedSchedule(
        notificationId,
        'Medication Reminder',
        'Time to take ${reminder.medicineName} ${reminder.dosage}',
        tz.TZDateTime.from(scheduledDate, tz.local), // convert to timezone-aware date
        _getNotificationDetails(reminder),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminder.id,
      );

      print('Scheduled reminder notification for ${reminder.medicineName} at ${reminder.timeString}');
    } catch (e) {
      print('Failed to schedule reminder notification: $e');
    }
  }

  /// Schedule expiry alert notification
  Future<void> scheduleExpiryAlert(MedicineModel medicine) async {
    try {
      if (!_isInitialized) await initialize();

      final notificationId = medicine.id.hashCode;

      // Schedule notification 7 days before expiry
      final alertDate = medicine.expiryDate.subtract(const Duration(days: 7));

      if (alertDate.isAfter(DateTime.now())) {
        await _localNotifications.zonedSchedule(
          notificationId,
          'Medicine Expiry Alert',
          '${medicine.name} expires in 7 days on ${_formatDate(medicine.expiryDate)}',
          tz.TZDateTime.from(alertDate, tz.local), // convert to timezone date
          _getExpiryNotificationDetails(medicine),
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
          payload: medicine.id,
        );

        print('Scheduled expiry alert for ${medicine.name}');
      }
    } catch (e) {
      print('Failed to schedule expiry alert: $e');
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

      await _localNotifications.show(
        id,
        title,
        body,
        details ?? _getDefaultNotificationDetails(),
        payload: payload,
      );
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
    
    // Check if reminder is due today
    if (reminder.isDueToday) {
      final reminderTime = DateTime(
        now.year,
        now.month,
        now.day,
        reminder.time.hour,
        reminder.time.minute,
      );
      
      // If time has passed today, schedule for tomorrow
      if (reminderTime.isBefore(now)) {
        return reminderTime.add(const Duration(days: 1));
      }
      
      return reminderTime;
    }
    
    // Find next occurrence - simplified scheduling
    return DateTime(
      now.year,
      now.month,
      now.day + 1,
      reminder.time.hour,
      reminder.time.minute,
    );
  }

  NotificationDetails _getNotificationDetails(ReminderModel reminder) {
    const androidDetails = AndroidNotificationDetails(
      'medicine_expiry',
      'Medicine Expiry Alerts',
      channelDescription: 'Notifications for medicine expiry alerts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      enableVibration: true,
      enableLights: true,
      color: Color(0xFFFF9800),
    );


    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  NotificationDetails _getExpiryNotificationDetails(MedicineModel medicine) {
    const androidDetails = AndroidNotificationDetails(
      'medicine_expiry',
      'Medicine Expiry Alerts',
      channelDescription: 'Notifications for medicine expiry alerts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      enableVibration: true,
      enableLights: true,
      color: Color(0xFFFF9800),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  NotificationDetails _getDefaultNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      'general',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Send push notification to specific user
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // This would typically be done through a backend service
      // For now, we'll just log the attempt
      print('Push notification would be sent to user $userId: $title - $body');
      
      if (data != null) {
        print('With data: $data');
      }
    } catch (e) {
      print('Failed to send push notification: $e');
    }
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

  /// Subscribe to topic for group notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Failed to unsubscribe from topic: $e');
    }
  }
}
