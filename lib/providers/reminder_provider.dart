import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/reminder_model.dart';
import '/models/user_model.dart';

class ReminderProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<ReminderModel> _reminders = [];
  List<ReminderModel> _todayReminders = [];
  bool _isLoading = false;
  String? _error;

  List<ReminderModel> get reminders => _reminders;
  List<ReminderModel> get todayReminders => _todayReminders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ReminderProvider() {
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      _isLoading = true;
      notifyListeners();

      final querySnapshot = await _firestore
          .collection('reminders')
          .where('isActive', isEqualTo: true)
          .orderBy('time')
          .get();

      _reminders = querySnapshot.docs
          .map((doc) => ReminderModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      _updateTodayReminders();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load reminders: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateTodayReminders() {
    _todayReminders = _reminders.where((reminder) => reminder.isDueToday).toList();
    _todayReminders.sort((a, b) => a.time.hour.compareTo(b.time.hour));
  }

  Future<bool> addReminder({
    required String medicineId,
    required String medicineName,
    required String dosage,
    required TimeOfDay time,
    required ReminderFrequency frequency,
    List<int>? customDays,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final reminder = ReminderModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        medicineId: medicineId,
        medicineName: medicineName,
        dosage: dosage,
        time: time,
        frequency: frequency,
        customDays: customDays,
        status: ReminderStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      await _firestore
          .collection('reminders')
          .doc(reminder.id)
          .set(reminder.toJson());

      _reminders.add(reminder);
      _updateTodayReminders();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add reminder: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateReminder({
    required String id,
    TimeOfDay? time,
    ReminderFrequency? frequency,
    List<int>? customDays,
    bool? isActive,
  }) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == id);
      if (index == -1) return false;

      final updatedReminder = _reminders[index].copyWith(
        time: time,
        frequency: frequency,
        customDays: customDays,
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('reminders')
          .doc(id)
          .update(updatedReminder.toJson());

      _reminders[index] = updatedReminder;
      _updateTodayReminders();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update reminder: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReminder(String id) async {
    try {
      await _firestore.collection('reminders').doc(id).delete();
      
      _reminders.removeWhere((r) => r.id == id);
      _updateTodayReminders();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete reminder: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> markReminderAsTaken(String id) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == id);
      if (index == -1) return false;

      final updatedReminder = _reminders[index].copyWith(
        status: ReminderStatus.taken,
        takenAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('reminders')
          .doc(id)
          .update(updatedReminder.toJson());

      _reminders[index] = updatedReminder;
      _updateTodayReminders();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to mark reminder as taken: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> markReminderAsMissed(String id) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == id);
      if (index == -1) return false;

      final updatedReminder = _reminders[index].copyWith(
        status: ReminderStatus.missed,
        missedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('reminders')
          .doc(id)
          .update(updatedReminder.toJson());

      _reminders[index] = updatedReminder;
      _updateTodayReminders();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to mark reminder as missed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> snoozeReminder(String id, Duration duration) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == id);
      if (index == -1) return false;

      final newTime = TimeOfDay(
        hour: (_reminders[index].time.hour + duration.inHours) % 24,
        minute: _reminders[index].time.minute,
      );

      final updatedReminder = _reminders[index].copyWith(
        status: ReminderStatus.snoozed,
        time: newTime,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('reminders')
          .doc(id)
          .update(updatedReminder.toJson());

      _reminders[index] = updatedReminder;
      _updateTodayReminders();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to snooze reminder: $e';
      notifyListeners();
      return false;
    }
  }

  List<ReminderModel> getRemindersForDate(DateTime date) {
    return _reminders.where((reminder) {
      if (!reminder.isActive) return false;
      
      switch (reminder.frequency) {
        case ReminderFrequency.daily:
          return true;
        case ReminderFrequency.weekly:
          return reminder.customDays?.contains(date.weekday) ?? false;
        case ReminderFrequency.custom:
          return reminder.customDays?.contains(date.weekday) ?? false;
      }
    }).toList();
  }

  int getTodayProgress() {
    final taken = _todayReminders.where((r) => r.status == ReminderStatus.taken).length;
    final total = _todayReminders.length;
    return total > 0 ? taken : 0;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
