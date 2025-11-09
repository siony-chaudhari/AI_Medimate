import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_model.dart';
import 'notification_service.dart';

/// Service to check and manage reminder durations
class DurationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check all reminders for expired durations
  static Future<void> checkExpiredReminders() async {
    try {
      debugPrint("🔍 Checking for expired reminders...");

      // Get all active reminders with duration
      final querySnapshot = await _firestore
          .collection('reminders')
          .where('isActive', isEqualTo: true)
          .where('isCompleted', isEqualTo: false)
          .get();

      int expiredCount = 0;

      for (final doc in querySnapshot.docs) {
        try {
          final data = {...doc.data(), 'id': doc.id};
          final reminder = ReminderModel.fromJson(data);

          // Check if reminder has duration and is expired
          if (reminder.durationDays != null && reminder.isDurationExpired) {
            debugPrint("⏰ Reminder expired: ${reminder.medicineName}");
            await _completeReminder(reminder);
            expiredCount++;
          }
        } catch (e) {
          debugPrint("❌ Error processing reminder ${doc.id}: $e");
        }
      }

      debugPrint("✅ Checked reminders. Found $expiredCount expired.");
    } catch (e) {
      debugPrint("❌ Error checking expired reminders: $e");
    }
  }

  /// Mark a reminder as completed
  static Future<void> _completeReminder(ReminderModel reminder) async {
    try {
      debugPrint("📝 Completing reminder: ${reminder.medicineName}");

      // Update in Firestore
      await _firestore.collection('reminders').doc(reminder.id).update({
        'status': 'completed',
        'isCompleted': true,
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Cancel any pending notifications
      await NotificationService.cancelNotification(
        reminder.id.hashCode.abs() % 100000,
      );

      // Show completion notification
      await _showCompletionNotification(reminder);

      debugPrint("✅ Reminder completed: ${reminder.medicineName}");
    } catch (e) {
      debugPrint("❌ Error completing reminder: $e");
    }
  }

  /// Show completion notification
  static Future<void> _showCompletionNotification(ReminderModel reminder) async {
    try {
      await NotificationService.showCompletionNotification(
        medicineName: reminder.medicineName,
        durationDays: reminder.durationDays ?? 0,
      );
    } catch (e) {
      debugPrint("❌ Error showing completion notification: $e");
    }
  }

  /// Get reminders expiring soon (within 2 days)
  static Future<List<ReminderModel>> getExpiringSoonReminders() async {
    try {
      final querySnapshot = await _firestore
          .collection('reminders')
          .where('isActive', isEqualTo: true)
          .where('isCompleted', isEqualTo: false)
          .get();

      final expiringSoon = <ReminderModel>[];

      for (final doc in querySnapshot.docs) {
        try {
          final data = {...doc.data(), 'id': doc.id};
          final reminder = ReminderModel.fromJson(data);

          if (reminder.durationDays != null && 
              reminder.remainingDays > 0 && 
              reminder.remainingDays <= 2) {
            expiringSoon.add(reminder);
          }
        } catch (e) {
          debugPrint("❌ Error processing reminder: $e");
        }
      }

      return expiringSoon;
    } catch (e) {
      debugPrint("❌ Error getting expiring reminders: $e");
      return [];
    }
  }

  /// Manually complete a reminder
  static Future<void> manuallyCompleteReminder(String reminderId) async {
    try {
      final doc = await _firestore.collection('reminders').doc(reminderId).get();
      if (!doc.exists) return;

      final data = {...doc.data()!, 'id': doc.id};
      final reminder = ReminderModel.fromJson(data);

      await _completeReminder(reminder);
    } catch (e) {
      debugPrint("❌ Error manually completing reminder: $e");
    }
  }

  /// Extend reminder duration
  static Future<void> extendDuration(String reminderId, int additionalDays) async {
    try {
      final doc = await _firestore.collection('reminders').doc(reminderId).get();
      if (!doc.exists) return;

      final data = {...doc.data()!, 'id': doc.id};
      final reminder = ReminderModel.fromJson(data);

      if (reminder.endDate == null) return;

      final newEndDate = reminder.endDate!.add(Duration(days: additionalDays));
      final newDurationDays = (reminder.durationDays ?? 0) + additionalDays;

      await _firestore.collection('reminders').doc(reminderId).update({
        'endDate': newEndDate.toIso8601String(),
        'durationDays': newDurationDays,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      debugPrint("✅ Extended duration by $additionalDays days");
    } catch (e) {
      debugPrint("❌ Error extending duration: $e");
    }
  }

  /// Renew a completed reminder
  static Future<void> renewReminder(String reminderId, int newDurationDays) async {
    try {
      final now = DateTime.now();
      final newEndDate = now.add(Duration(days: newDurationDays));

      await _firestore.collection('reminders').doc(reminderId).update({
        'status': 'pending',
        'isCompleted': false,
        'isActive': true,
        'startDate': now.toIso8601String(),
        'endDate': newEndDate.toIso8601String(),
        'durationDays': newDurationDays,
        'updatedAt': now.toIso8601String(),
      });

      debugPrint("✅ Renewed reminder for $newDurationDays days");
    } catch (e) {
      debugPrint("❌ Error renewing reminder: $e");
    }
  }
}
