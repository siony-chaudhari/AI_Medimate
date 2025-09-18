import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/reminder_provider.dart';
import '/models/reminder_model.dart';
import '/utils/constants.dart';
import 'package:intl/intl.dart';

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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddReminderDialog(context);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
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
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
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
                children: [
                  Text(
                    DateFormat('E').format(date),
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.primary 
                          : (isToday ? AppColors.primary.withOpacity(0.1) : Colors.transparent),
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      border: isSelected 
                          ? null 
                          : Border.all(
                              color: isToday ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3),
                            ),
                    ),
                    child: Center(
                      child: Text(
                        date.day.toString(),
                        style: AppTextStyles.body1.copyWith(
                          color: isSelected 
                              ? Colors.white 
                              : (isToday ? AppColors.primary : AppColors.textSecondary),
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
    return Consumer<ReminderProvider>(
      builder: (context, reminderProvider, child) {
        final totalReminders = reminderProvider.todayReminders.length;
        final completedReminders = reminderProvider.getTodayProgress();
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
    return Consumer<ReminderProvider>(
      builder: (context, reminderProvider, child) {
        final reminders = reminderProvider.getRemindersForDate(_selectedDate);
        
        if (reminders.isEmpty) {
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
                  'Tap the + button to add a reminder',
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
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            final reminder = reminders[index];
            return _buildReminderCard(reminder);
          },
        );
      },
    );
  }

  Widget _buildReminderCard(ReminderModel reminder) {
    final isOverdue = reminder.isOverdue;
    final isCompleted = reminder.status == ReminderStatus.taken;
    
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
            color: _getReminderColor(reminder).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          child: Icon(
            _getReminderIcon(reminder),
            color: _getReminderColor(reminder),
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
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOverdue && !isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingS,
                  vertical: AppSizes.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusS),
                ),
                child: Text(
                  'Overdue',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: AppSizes.paddingS),
            Switch(
              value: isCompleted,
              onChanged: (value) {
                if (value) {
                  Provider.of<ReminderProvider>(context, listen: false).markReminderAsTaken(reminder.id);
                } else {
                  Provider.of<ReminderProvider>(context, listen: false).markReminderAsMissed(reminder.id);
                }
              },
              activeColor: AppColors.success,
            ),
          ],
        ),
        onTap: () {
          _showReminderDetailsDialog(context, reminder);
        },
      ),
    );
  }

  Color _getReminderColor(ReminderModel reminder) {
    switch (reminder.status) {
      case ReminderStatus.taken:
        return AppColors.success;
      case ReminderStatus.missed:
        return AppColors.error;
      case ReminderStatus.snoozed:
        return AppColors.warning;
      case ReminderStatus.pending:
        return reminder.isOverdue ? AppColors.error : AppColors.primary;
    }
  }

  IconData _getReminderIcon(ReminderModel reminder) {
    switch (reminder.status) {
      case ReminderStatus.taken:
        return Icons.check_circle;
      case ReminderStatus.missed:
        return Icons.cancel;
      case ReminderStatus.snoozed:
        return Icons.snooze;
      case ReminderStatus.pending:
        return reminder.isOverdue ? Icons.warning : Icons.access_time;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  void _showAddReminderDialog(BuildContext context) {
    // TODO: Implement add reminder dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add reminder feature coming soon!')),
    );
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
            Text('Frequency: ${reminder.frequency.toString().split('.').last}'),
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
