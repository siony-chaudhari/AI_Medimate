import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/reminder_provider.dart';
import '/providers/medicine_provider.dart';
import '/models/reminder_model.dart';
import '/utils/constants.dart';
import 'package:intl/intl.dart';
import '/services/notification_service.dart';
import '/screens/add_edit_reminder_screen.dart';
import '/screens/add_medicine_screen.dart';


class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Date selector
            _buildDateSelector(),
            
            // Today's progress
            _buildTodayProgress(),
            
            // Reminders list
            Expanded(
              child: _buildRemindersList(),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Debug button
          // FloatingActionButton.small(
          //   onPressed: () async {
          //     // Test notification immediately
          //     await NotificationService.showTestNotification();
          //
          //     // Show pending notifications
          //     await NotificationService.getAllPendingNotifications();
          //
          //     if (context.mounted) {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(content: Text('Test notification sent! Check logs for details.')),
          //       );
          //     }
          //   },
          //   backgroundColor: Colors.orange,
          //   child: const Icon(Icons.bug_report, color: Colors.white),
          // ),
          // const SizedBox(height: 8),
          // // Add reminder button
          FloatingActionButton(
            onPressed: () {
              _showAddReminderDialog(context);
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: Icon(
              Icons.medication,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            AppStrings.today,
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return SizedBox( // 🔹 use SizedBox to fix height exactly
      height: 95, // increased to give enough vertical room
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index - 3));
          final isSelected = _isSameDay(date, _selectedDate);
          final isToday = _isSameDay(date, DateTime.now());

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: AppSizes.paddingM),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // 🔹 centers vertically
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible( // 🔹 prevents text from pushing past constraints
                    child: Text(
                      DateFormat('E').format(date),
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isToday
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.transparent),
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      border: isSelected
                          ? null
                          : Border.all(
                        color: isToday
                            ? AppColors.primary
                            : AppColors.textSecondary.withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        date.day.toString(),
                        style: AppTextStyles.body1.copyWith(
                          color: isSelected
                              ? Colors.white
                              : (isToday
                              ? AppColors.primary
                              : AppColors.textSecondary),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildTodayProgress() {
    return Consumer2<ReminderProvider, MedicineProvider>(
      builder: (context, reminderProvider, medicineProvider, child) {
        // Get existing medicine names
        final existingMedicineNames = medicineProvider.medicines.map((m) => m.name).toList();
        
        // Filter today's reminders to only include those with existing medicines
        final allTodayReminders = reminderProvider.todayReminders;
        final validTodayReminders = allTodayReminders.where((reminder) {
          return existingMedicineNames.any(
            (name) => name.toLowerCase().trim() == reminder.medicineName.toLowerCase().trim(),
          );
        }).toList();
        
        final totalReminders = validTodayReminders.length;
        final completedReminders = validTodayReminders.where((r) => r.status == ReminderStatus.taken).length;
        final progress = totalReminders > 0 ? completedReminders / totalReminders : 0.0;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
          padding: const EdgeInsets.all(AppSizes.paddingL),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.todayProgress,
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.keepUpGreatWork,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$completedReminders/$totalReminders',
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Completed',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.textSecondary.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRemindersList() {
    return Consumer2<ReminderProvider, MedicineProvider>(
      builder: (context, reminderProvider, medicineProvider, child) {
        // Get existing medicine names
        final existingMedicineNames = medicineProvider.medicines.map((m) => m.name).toList();
        
        // Filter reminders to only show those with existing medicines
        final allReminders = reminderProvider.getRemindersForDate(_selectedDate);
        final validReminders = allReminders.where((reminder) {
          return existingMedicineNames.any(
            (name) => name.toLowerCase().trim() == reminder.medicineName.toLowerCase().trim(),
          );
        }).toList();
        
        if (validReminders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 64,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No reminders for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add a medicine and reminder',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          itemCount: validReminders.length,
          itemBuilder: (context, index) {
            final reminder = validReminders[index];
            return _buildReminderCard(reminder);
          },
        );
      },
    );
  }

  Widget _buildReminderCard(ReminderModel reminder) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSizes.paddingM),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          child: Icon(
            Icons.medication,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          reminder.medicineName,
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              reminder.dosage,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              reminder.timeString,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            // Show duration progress if available
            if (reminder.durationDays != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    reminder.durationText,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: reminder.progressPercentage,
                backgroundColor: AppColors.textSecondary.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 22),
          onPressed: () async {
            final provider = Provider.of<ReminderProvider>(context, listen: false);
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Reminder'),
                content: Text('Are you sure you want to delete "${reminder.medicineName}" reminder?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await provider.deleteReminder(reminder.id);
              await NotificationService.cancelNotification(reminder.id.hashCode.abs() % 100000);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${reminder.medicineName} deleted successfully'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
              setState(() {});
            }
          },
        ),
        onTap: () async {
          final updatedReminder = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditReminderScreen(reminder: reminder),
            ),
          );

          if (updatedReminder != null && context.mounted) {
            final provider = Provider.of<ReminderProvider>(context, listen: false);
            await provider.updateReminderTime(updatedReminder.id, updatedReminder.time);

            await NotificationService.cancelNotification(reminder.id.hashCode.abs() % 100000);

            await NotificationService.scheduleNotification(
              id: updatedReminder.id.hashCode.abs() % 100000,
              title: "It's time to take your ${updatedReminder.medicineName}",
              body: "Dosage: ${updatedReminder.dosage}",
              scheduledTime: DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
                updatedReminder.time.hour,
                updatedReminder.time.minute,
              ),
              reminderId: updatedReminder.id,
              medicineName: updatedReminder.medicineName,
            );

            setState(() {});
          }
        },
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  void _showAddReminderDialog(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMedicineScreen(),
      ),
    );

    if (result == true && mounted) {
      // Refresh the reminders list
      setState(() {});
    }
  }

  void _showReminderDetailsDialog(BuildContext context, ReminderModel reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reminder.medicineName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dosage: ${reminder.dosage}'),
            Text('Time: ${reminder.timeString}'),
            // Text('Frequency: ${reminder.frequency.toString().split('.').last}'),
            Text('Status: ${reminder.status.toString().split('.').last}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
