import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  /// Get Android implementation for permission checks
  static AndroidFlutterLocalNotificationsPlugin? getAndroidImplementation() {
    return _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  }

  // Initialize timezone and notification settings
  static Future<void> init() async {
    tz.initializeTimeZones();

    // ✅ Explicitly set timezone to India (important!)
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    // Android initialization
    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();

    // Combine both
    const InitializationSettings initSettings =
    InitializationSettings(android: androidInit, iOS: iosInit);

    await _notifications.initialize(initSettings);
  }

  // Ask permission on iOS / Android 13+
  static Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final android = getAndroidImplementation();
      
      // Request basic notification permission
      final notificationPermission = await android?.requestNotificationsPermission();
      print("📱 Notification permission granted: $notificationPermission");
      
      // Check if notifications are enabled
      final notificationsEnabled = await android?.areNotificationsEnabled() ?? false;
      print("📱 Notifications enabled: $notificationsEnabled");
      
      // Check exact alarm permission
      final canScheduleExact = await android?.canScheduleExactNotifications() ?? false;
      print("📱 Can schedule exact notifications: $canScheduleExact");
      
    } else if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Check all notification permissions
  static Future<Map<String, bool>> checkPermissions() async {
    final permissions = <String, bool>{};
    
    if (Platform.isAndroid) {
      final android = getAndroidImplementation();
      permissions['notifications_enabled'] = await android?.areNotificationsEnabled() ?? false;
      permissions['can_schedule_exact'] = await android?.canScheduleExactNotifications() ?? false;
    }
    
    return permissions;
  }

  /// 🔔 Schedule a notification at a specific time (with daily repetition)
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      final now = DateTime.now();
      DateTime scheduled = scheduledTime;

      // If the time has passed today, schedule for tomorrow
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      print("📅 Scheduling Notification:");
      print("➡️ ID: $id");
      print("➡️ Title: $title");
      print("➡️ Scheduled Time: $scheduled");
      print("➡️ Current Time: $now");
      print("➡️ TZ DateTime: ${tz.TZDateTime.from(scheduled, tz.local)}");

      // Check if notifications are enabled
      final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final permissionGranted = await android?.areNotificationsEnabled() ?? false;
      print("➡️ Notifications Enabled: $permissionGranted");

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduled, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Medicine Reminders',
            channelDescription: 'Reminds you to take your medicine on time',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            channelShowBadge: true,
            autoCancel: false,
            ongoing: false,
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true, 
            presentSound: true,
            presentBadge: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print("✅ Notification scheduled successfully!");
      
      // Verify the notification was scheduled
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      print("📋 Total pending notifications: ${pendingNotifications.length}");
      
    } catch (e) {
      print("❌ Failed to schedule notification: $e");
      print("❌ Stack trace: ${StackTrace.current}");
    }
  }


  /// 🧹 Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// 🧼 Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// 📋 Debug helper: show all active notifications
  static Future<List<ActiveNotification>> getPendingNotifications() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final active = await android?.getActiveNotifications() ?? [];
    print("🔍 Active notifications count: ${active.length}");
    return active;
  }

  /// 🧪 Test notification (shows immediately)
  static Future<void> showTestNotification() async {
    try {
      await _notifications.show(
        999,
        'Test Notification',
        'This is a test to verify notifications are working',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notifications to verify setup',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
          ),
        ),
      );
      print("✅ Test notification sent!");
    } catch (e) {
      print("❌ Failed to send test notification: $e");
    }
  }

  /// 📊 Get all pending notification requests
  static Future<List<PendingNotificationRequest>> getAllPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      print("📋 Pending notifications:");
      for (final notification in pending) {
        print("  - ID: ${notification.id}, Title: ${notification.title}");
      }
      return pending;
    } catch (e) {
      print("❌ Failed to get pending notifications: $e");
      return [];
    }
  }
}
