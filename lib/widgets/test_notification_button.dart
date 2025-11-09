import 'package:flutter/material.dart';
import '/services/notification_service.dart';

/// Floating button to test notifications
class TestNotificationButton extends StatelessWidget {
  const TestNotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () async {
        debugPrint("🧪 Test button pressed");
        await NotificationService.showTestNotification();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Test notification sent! Click a button in the notification.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      icon: const Icon(Icons.bug_report),
      label: const Text('Test Notification'),
      backgroundColor: Colors.orange,
    );
  }
}
