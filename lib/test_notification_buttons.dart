import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/notification_service.dart';

/// Test screen to verify notification button functionality
class TestNotificationButtons extends StatefulWidget {
  const TestNotificationButtons({super.key});

  @override
  State<TestNotificationButtons> createState() => _TestNotificationButtonsState();
}

class _TestNotificationButtonsState extends State<TestNotificationButtons> {
  final _firestore = FirebaseFirestore.instance;
  String _testReminderId = '';
  String _status = 'Waiting...';

  @override
  void initState() {
    super.initState();
    _createTestReminder();
  }

  Future<void> _createTestReminder() async {
    try {
      setState(() => _status = 'Creating test reminder...');
      
      // Create a test reminder
      final docRef = await _firestore.collection('reminders').add({
        'medicineId': 'test_medicine',
        'medicineName': 'Test Medicine',
        'dosage': '1 tablet',
        'time': '${DateTime.now().hour}:${DateTime.now().minute}',
        'frequency': 'daily',
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': true,
        'notificationsEnabled': true,
      });
      
      _testReminderId = docRef.id;
      
      setState(() => _status = 'Test reminder created: $_testReminderId');
      
      // Listen to changes
      _firestore.collection('reminders').doc(_testReminderId).snapshots().listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          setState(() {
            _status = 'Current status: ${data?['status']}\n'
                     'Updated at: ${data?['updatedAt']}\n'
                     'Taken at: ${data?['takenAt']}\n'
                     'Missed at: ${data?['missedAt']}';
          });
        }
      });
      
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      setState(() => _status = 'Sending test notification...');
      
      await NotificationService.scheduleNotification(
        id: 12345,
        title: "Test Medicine Reminder",
        body: "Click a button to test",
        scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
        reminderId: _testReminderId,
        medicineName: 'Test Medicine',
      );
      
      setState(() => _status = 'Test notification scheduled for 5 seconds from now');
    } catch (e) {
      setState(() => _status = 'Error sending notification: $e');
    }
  }

  Future<void> _testDirectUpdate() async {
    try {
      setState(() => _status = 'Testing direct Firestore update...');
      
      await _firestore.collection('reminders').doc(_testReminderId).update({
        'status': 'taken',
        'takenAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      setState(() => _status = 'Direct update completed');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _cleanup() async {
    try {
      if (_testReminderId.isNotEmpty) {
        await _firestore.collection('reminders').doc(_testReminderId).delete();
        setState(() => _status = 'Test reminder deleted');
      }
    } catch (e) {
      setState(() => _status = 'Error cleaning up: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notification Buttons'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _cleanup,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _status,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendTestNotification,
              child: const Text('Send Test Notification'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _testDirectUpdate,
              child: const Text('Test Direct Firestore Update'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              '1. Click "Send Test Notification"\n'
              '2. Wait 5 seconds for notification\n'
              '3. Click "Taken" or "Missed" button\n'
              '4. Watch the status update above\n'
              '5. Check console logs for debugging',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
