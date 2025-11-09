import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'ml_rescheduling_service.dart';
import 'tts_service.dart';
import 'alarm_tts_service.dart';
import 'package:flutter/widgets.dart';

// Background notification handler - MUST be top-level function
// ---------------------------------------------------------------------------
// BACKGROUND HANDLER FOR NOTIFICATION ACTIONS
// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    final firestore = FirebaseFirestore.instance;

    final payload = response.payload;
    final actionId = response.actionId;

    if (payload == null || actionId == null) {
      debugPrint("❌ Missing payload or actionId");
      return;
    }

    final parts = payload.split('|');
    if (parts.length < 2) {
      debugPrint("❌ Invalid payload format: $payload");
      return;
    }

    final reminderId = parts[0];
    final medicineName = parts[1];
    final now = DateTime.now();

    debugPrint("📦 Background tap: $reminderId | $medicineName | $actionId");

    if (actionId == 'taken') {
      await firestore.collection('reminders').doc(reminderId).update({
        'status': 'taken',
        'takenAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });
      debugPrint("✅ Updated reminder $reminderId as TAKEN");
    } else if (actionId == 'missed') {
      await firestore.collection('reminders').doc(reminderId).update({
        'status': 'missed',
        'missedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });
      debugPrint("✅ Updated reminder $reminderId as MISSED");
    }
  } catch (e, stack) {
    debugPrint("❌ Error in background handler: $e");
    debugPrint(stack.toString());
  }
}


class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  /// Get Android implementation for permission checks
  static AndroidFlutterLocalNotificationsPlugin? getAndroidImplementation() {
    return _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  }

  /// Verify notification service is properly initialized
  static Future<bool> verifyInitialization() async {
    try {
      debugPrint("🔍 Verifying notification service...");
      
      final android = getAndroidImplementation();
      if (android == null) {
        debugPrint("❌ Android implementation not found");
        return false;
      }
      
      final notificationsEnabled = await android.areNotificationsEnabled() ?? false;
      debugPrint("📱 Notifications enabled: $notificationsEnabled");
      
      final canScheduleExact = await android.canScheduleExactNotifications() ?? false;
      debugPrint("📱 Can schedule exact: $canScheduleExact");
      
      final pending = await _notifications.pendingNotificationRequests();
      debugPrint("📱 Pending notifications: ${pending.length}");
      
      debugPrint("✅ Notification service verification complete");
      return notificationsEnabled;
    } catch (e) {
      debugPrint("❌ Error verifying notification service: $e");
      return false;
    }
  }

  // Initialize timezone and notification settings
  static Future<void> init() async {
    debugPrint("🔧 Initializing NotificationService...");
    
    tz.initializeTimeZones();

    // ✅ Explicitly set timezone to India (important!)
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    // Initialize TTS Service
    await TTSService.init();

    // Android initialization
    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();

    // Combine both
    const InitializationSettings initSettings =
    InitializationSettings(android: androidInit, iOS: iosInit);

    final initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    debugPrint("✅ NotificationService initialized: $initialized");
    debugPrint("✅ Callback registered for notification actions");
  }

  /// Handle notification button clicks
  static void _onNotificationResponse(NotificationResponse response) async {
    // CRITICAL: Log immediately to verify this is being called
    debugPrint("=" * 80);
    debugPrint("🔔 NOTIFICATION RESPONSE RECEIVED!");
    debugPrint("=" * 80);
    debugPrint("Response ID: ${response.id}");
    debugPrint("Notification ID: ${response.notificationResponseType}");
    debugPrint("Action ID: ${response.actionId}");
    debugPrint("Payload: ${response.payload}");
    debugPrint("Input: ${response.input}");
    debugPrint("=" * 80);
    
    // Extract medicine name from payload and speak it
    final payload = response.payload;
    if (payload != null) {
      final parts = payload.split('|');
      if (parts.length >= 2) {
        final medicineName = parts[1];
        debugPrint("🔊 Speaking medicine name: $medicineName");
        await TTSService.speakMedicineReminder(medicineName);
      }
    }
    
    // final payload = response.payload;
    final actionId = response.actionId;
    
    // Test if callback is working at all
    if (actionId == null) {
      debugPrint("⚠️ ActionId is null - user tapped notification body, not a button");
      return;
    }
    
    debugPrint("✅ Action button clicked: $actionId");
    
    if (payload == null) {
      debugPrint("❌ Payload is null - cannot process action");
      return;
    }
    
    debugPrint("📦 Payload received: $payload");
    
    final parts = payload.split('|');
    debugPrint("📦 Payload parts: ${parts.length}");
    
    if (parts.length >= 2) {
      final reminderId = parts[0];
      final medicineName = parts[1];
      
      debugPrint("✅ Parsed successfully:");
      debugPrint("   Reminder ID: $reminderId");
      debugPrint("   Medicine: $medicineName");
      debugPrint("   Action: $actionId");
      debugPrint("🚀 Starting to handle action...");
      
      // Handle the action
      try {
        await _handleNotificationAction(reminderId, actionId, medicineName);
        debugPrint("✅ Action handling completed successfully");
      } catch (e, stackTrace) {
        debugPrint("❌ Error in action handling: $e");
        debugPrint("Stack trace: $stackTrace");
      }
    } else {
      debugPrint("❌ Invalid payload format: expected 2 parts, got ${parts.length}");
      debugPrint("   Parts: $parts");
    }
  }

  /// Process notification button actions with ML integration
  static Future<void> _handleNotificationAction(String reminderId, String actionId, String medicineName) async {
    try {
      print("📝 Starting _handleNotificationAction");
      print("   Reminder ID: $reminderId");
      print("   Action: $actionId");
      print("   Medicine: $medicineName");
      
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();
      
      // Get reminder details
      print("📥 Fetching reminder document from Firestore...");
      final reminderDoc = await firestore.collection('reminders').doc(reminderId).get();
      
      if (!reminderDoc.exists) {
        print("❌ Reminder document not found: $reminderId");
        return;
      }
      
      final reminderData = reminderDoc.data();
      print("✅ Reminder document found");
      print("   Current status: ${reminderData?['status']}");
      
      switch (actionId) {
        case 'taken':
          print("✅ Marking $medicineName as TAKEN");
          
          await firestore.collection('reminders').doc(reminderId).update({
            'status': 'taken',
            'takenAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          });
          
          print("✅ Firestore updated with 'taken' status");
          
          // Record for ML learning
          await _recordMLAction(reminderId, medicineName, 'taken', now, reminderData);
          
          await _notifications.show(
            99999,
            '✅ Medicine Taken',
            '$medicineName marked as taken successfully!',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'status_channel',
                'Status Updates',
                channelDescription: 'Medicine status updates',
                importance: Importance.low,
                priority: Priority.low,
                autoCancel: true,
              ),
            ),
          );
          
          print("✅ Success notification shown");
          break;
          
        case 'missed':
          print("❌ Marking $medicineName as MISSED - Initiating ML Rescheduling");
          
          await firestore.collection('reminders').doc(reminderId).update({
            'status': 'missed',
            'missedAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          });
          
          print("✅ Firestore updated with 'missed' status");
          
          // Record for ML learning
          await _recordMLAction(reminderId, medicineName, 'missed', now, reminderData);
          
          // 🤖 ML-powered auto-rescheduling
          await _performMLRescheduling(reminderId, medicineName, reminderData, now);
          
          print("✅ ML rescheduling completed");
          break;
          
        default:
          print("❌ Unknown action: $actionId");
      }
    } catch (e, stackTrace) {
      print("❌ Error handling notification action: $e");
      print("❌ Stack trace: $stackTrace");
    }
  }
  
  /// Record action for ML learning
  static Future<void> _recordMLAction(
    String reminderId, 
    String medicineName, 
    String action, 
    DateTime timestamp,
    Map<String, dynamic>? reminderData
  ) async {
    try {
      final mlService = MLReschedulingService();
      await mlService.initialize();
      
      DateTime? rescheduledFrom;
      if (reminderData != null && reminderData['rescheduledFrom'] != null) {
        rescheduledFrom = DateTime.parse(reminderData['rescheduledFrom']);
      }
      
      await mlService.recordReminderAction(
        reminderId: reminderId,
        medicineName: medicineName,
        action: action,
        timestamp: timestamp,
        rescheduledFrom: rescheduledFrom,
      );
    } catch (e) {
      print("❌ Error recording ML action: $e");
    }
  }
  
  /// Perform ML-powered rescheduling
  static Future<void> _performMLRescheduling(
    String reminderId,
    String medicineName, 
    Map<String, dynamic>? reminderData,
    DateTime missedTime
  ) async {
    try {
      if (reminderData == null) return;
      
      final timeStr = reminderData['time'] as String?;
      if (timeStr == null) return;
      
      final timeParts = timeStr.split(':');
      if (timeParts.length != 2) return;
      
      final originalTime = DateTime(
        missedTime.year,
        missedTime.month,
        missedTime.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      
      // 🤖 Use ML to predict optimal reschedule time
      final mlService = MLReschedulingService();
      await mlService.initialize();
      
      final predictedTime = await mlService.predictOptimalRescheduleTime(
        medicineName: medicineName,
        originalTime: originalTime,
        missedTime: missedTime,
      );
      
      if (predictedTime != null) {
        await _createRescheduledReminder(
          reminderId, 
          medicineName, 
          reminderData, 
          predictedTime,
          originalTime
        );
        
        await _notifications.show(
          99997,
          '🤖 Smart Rescheduling',
          '$medicineName automatically rescheduled to ${DateFormat('hh:mm a').format(predictedTime)} based on your patterns',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'ml_channel',
              'ML Rescheduling',
              channelDescription: 'Smart rescheduling notifications',
              importance: Importance.high,
              priority: Priority.high,
              autoCancel: true,
            ),
          ),
        );
      } else {
        await _performDefaultRescheduling(reminderId, medicineName, reminderData, missedTime);
      }
    } catch (e) {
      print("❌ Error in ML rescheduling: $e");
      await _performDefaultRescheduling(reminderId, medicineName, reminderData, missedTime);
    }
  }
  
  /// Create rescheduled reminder
  static Future<void> _createRescheduledReminder(
    String originalReminderId,
    String medicineName,
    Map<String, dynamic> originalData,
    DateTime newTime,
    DateTime originalTime
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final newReminderId = '${originalReminderId}_rescheduled_${DateTime.now().millisecondsSinceEpoch}';
      
      await firestore.collection('reminders').doc(newReminderId).set({
        ...originalData,
        'id': newReminderId,
        'time': '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}',
        'status': 'pending',
        'isRescheduled': true,
        'originalReminderId': originalReminderId,
        'rescheduledFrom': originalTime.toIso8601String(),
        'rescheduledAt': DateTime.now().toIso8601String(),
        'mlPredicted': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      final notificationId = newReminderId.hashCode.abs() % 100000;
      await scheduleNotification(
        id: notificationId,
        title: "🔄 Rescheduled: It's time to take your $medicineName",
        body: "Smart rescheduling based on your patterns",
        scheduledTime: newTime,
        reminderId: newReminderId,
        medicineName: medicineName,
      );
      
      print("✅ Created ML-rescheduled reminder for $medicineName at ${DateFormat('hh:mm a').format(newTime)}");
    } catch (e) {
      print("❌ Error creating rescheduled reminder: $e");
    }
  }
  
  /// Fallback default rescheduling
  static Future<void> _performDefaultRescheduling(
    String reminderId,
    String medicineName,
    Map<String, dynamic>? reminderData,
    DateTime missedTime
  ) async {
    try {
      final defaultRescheduleTime = missedTime.add(const Duration(hours: 2));
      
      if (reminderData != null) {
        await _createRescheduledReminder(
          reminderId,
          medicineName,
          reminderData,
          defaultRescheduleTime,
          missedTime,
        );
      }
      
      await _notifications.show(
        99996,
        '⏰ Rescheduled',
        '$medicineName rescheduled to ${DateFormat('hh:mm a').format(defaultRescheduleTime)}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reschedule_channel',
            'Rescheduling',
            channelDescription: 'Medication rescheduling notifications',
            importance: Importance.high,
            priority: Priority.high,
            autoCancel: true,
          ),
        ),
      );
    } catch (e) {
      print("❌ Error in default rescheduling: $e");
    }
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
    String? reminderId,
    String? medicineName,
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
      print("➡️ Medicine: $medicineName");
      print("➡️ Scheduled Time: $scheduled");
      print("➡️ Current Time: $now");
      print("➡️ TZ DateTime: ${tz.TZDateTime.from(scheduled, tz.local)}");

      // Check if notifications are enabled
      final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final permissionGranted = await android?.areNotificationsEnabled() ?? false;
      print("➡️ Notifications Enabled: $permissionGranted");

      // Create payload for notification actions
      final payload = reminderId != null && medicineName != null 
          ? '$reminderId|$medicineName'
          : null;

      // Format scheduled time for display
      final timeString = DateFormat('hh:mm a EEEE').format(scheduled);

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduled, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Medicine Reminders',
            channelDescription: 'Reminds you to take your medicine on time',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            channelShowBadge: true,
            autoCancel: true,
            ongoing: false,
            styleInformation: BigTextStyleInformation(
              '$body\n\nScheduled for $timeString',
              htmlFormatBigText: false,
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true, 
            presentSound: true,
            presentBadge: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );

      print("✅ Notification scheduled successfully!");
      
      // Schedule TTS alarm to speak at the same time as notification
      if (medicineName != null && reminderId != null) {
        AlarmTTSService.scheduleAlarm(
          id: reminderId,
          scheduledTime: scheduled,
          medicineName: medicineName,
        );
        print("🔊 TTS alarm scheduled for notification time");
      }
      
      // If the notification is for now or very soon (within 5 seconds), speak it immediately
      if (scheduled.difference(now).inSeconds <= 5 && medicineName != null) {
        print("🔊 Speaking medicine reminder immediately...");
        await TTSService.speakMedicineReminder(medicineName);
      }
      
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
    // Also cancel the TTS alarm
    AlarmTTSService.cancelAlarm(id.toString());
    print("🔇 Cancelled notification and TTS alarm for ID: $id");
  }

  /// 🧼 Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    // Also cancel all TTS alarms
    AlarmTTSService.cancelAllAlarms();
    print("🔇 Cancelled all notifications and TTS alarms");
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
      debugPrint("=" * 80);
      debugPrint("🧪 SENDING TEST NOTIFICATION");
      debugPrint("=" * 80);
      
      // Speak the test medicine name
      await TTSService.speakMedicineReminder("Vitamin D");
      
      await _notifications.show(
        999,
        'TEST: It\'s time to take your Vitamin D',
        'Tap to hear the medicine name',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notifications to verify setup',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            styleInformation: BigTextStyleInformation(
              'Tap notification to hear TTS\n\nCheck console logs for debugging',
              htmlFormatBigText: false,
            ),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
          ),
        ),
        payload: 'test_reminder_123|Vitamin D',
      );
      
      debugPrint("✅ Test notification sent successfully!");
      debugPrint("   Notification ID: 999");
      debugPrint("   Payload: test_reminder_123|Vitamin D");
      debugPrint("   TTS spoken: Vitamin D");
      debugPrint("=" * 80);
    } catch (e, stackTrace) {
      debugPrint("❌ Failed to send test notification: $e");
      debugPrint("Stack trace: $stackTrace");
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

  /// 🎉 Show completion notification
  static Future<void> showCompletionNotification({
    required String medicineName,
    required int durationDays,
  }) async {
    try {
      debugPrint("🎉 Showing completion notification for $medicineName");

      await _notifications.show(
        99998,
        '🎉 Dosage Completed!',
        '$medicineName treatment completed after $durationDays days. Update reminder if needed.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'completion_channel',
            'Treatment Completion',
            channelDescription: 'Notifications when treatment duration is completed',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            styleInformation: BigTextStyleInformation(
              'Your treatment is complete! Tap to update or renew your reminder if you need to continue.',
              htmlFormatBigText: false,
            ),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
          ),
        ),
        payload: 'completion|$medicineName',
      );

      debugPrint("✅ Completion notification shown");
    } catch (e) {
      debugPrint("❌ Failed to show completion notification: $e");
    }
  }
}
