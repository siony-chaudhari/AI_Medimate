import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

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
      await _notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
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

      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      print("📅 Scheduling Notification:");
      print("➡️ ID: $id");
      print("➡️ Title: $title");
      print("➡️ Time: $scheduled");

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
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print("❌ Failed to schedule notification: $e");
      // Show guidance if user must manually allow exact alarms
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
}
