import 'dart:async';
import 'package:flutter/foundation.dart';
import 'tts_service.dart';

/// Service to schedule TTS alarms that speak at notification time
class AlarmTTSService {
  static final Map<String, Timer> _activeTimers = {};

  /// Schedule TTS to speak at a specific time
  static void scheduleAlarm({
    required String id,
    required DateTime scheduledTime,
    required String medicineName,
  }) {
    try {
      // Cancel any existing timer for this ID
      cancelAlarm(id);

      final now = DateTime.now();
      final difference = scheduledTime.difference(now);

      if (difference.isNegative) {
        debugPrint("⏰ Scheduled time is in the past, skipping TTS alarm");
        return;
      }

      debugPrint("⏰ Scheduling TTS alarm for $medicineName at $scheduledTime");
      debugPrint("⏰ Will trigger in ${difference.inSeconds} seconds");

      // Create a timer that will trigger at the scheduled time
      final timer = Timer(difference, () async {
        debugPrint("🔊 TTS ALARM TRIGGERED for $medicineName");
        await TTSService.speakMedicineReminder(medicineName);
        _activeTimers.remove(id);
      });

      _activeTimers[id] = timer;
      debugPrint("✅ TTS alarm scheduled successfully");
    } catch (e) {
      debugPrint("❌ Error scheduling TTS alarm: $e");
    }
  }

  /// Cancel a scheduled TTS alarm
  static void cancelAlarm(String id) {
    try {
      if (_activeTimers.containsKey(id)) {
        _activeTimers[id]?.cancel();
        _activeTimers.remove(id);
        debugPrint("🔇 TTS alarm cancelled for ID: $id");
      }
    } catch (e) {
      debugPrint("❌ Error cancelling TTS alarm: $e");
    }
  }

  /// Cancel all TTS alarms
  static void cancelAllAlarms() {
    try {
      for (final timer in _activeTimers.values) {
        timer.cancel();
      }
      _activeTimers.clear();
      debugPrint("🔇 All TTS alarms cancelled");
    } catch (e) {
      debugPrint("❌ Error cancelling all TTS alarms: $e");
    }
  }

  /// Get count of active alarms
  static int getActiveAlarmCount() {
    return _activeTimers.length;
  }

  /// Check if an alarm exists
  static bool hasAlarm(String id) {
    return _activeTimers.containsKey(id);
  }
}
