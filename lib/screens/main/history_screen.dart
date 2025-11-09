import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/reminder_provider.dart';
import '/models/reminder_model.dart';
import '/utils/constants.dart';
import 'package:intl/intl.dart';
import '/screens/add_edit_reminder_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'all'; // all, taken, missed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Filter and date selector
            _buildFilterSection(),
            
            // Statistics
            _buildStatistics(),
            
            // History list
            Expanded(
              child: _buildHistoryList(),
            ),
          ],
        ),
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
              Icons.history,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            AppStrings.history,
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
      child: Row(
        children: [
          // Filter buttons
          Expanded(
            child: Row(
              children: [
                _buildFilterChip('all', 'All'),
                const SizedBox(width: AppSizes.paddingS),
                _buildFilterChip('taken', 'Taken'),
                const SizedBox(width: AppSizes.paddingS),
                _buildFilterChip('missed', 'Missed'),
              ],
            ),
          ),
          
          // Date picker
          IconButton(
            onPressed: () => _selectDate(context),
            icon: Icon(
              Icons.calendar_today,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingM,
          vertical: AppSizes.paddingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body2.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Consumer<ReminderProvider>(
      builder: (context, reminderProvider, child) {
        // Get all reminders for the selected date
        final allReminders = reminderProvider.reminders.where((reminder) {
          if (!reminder.isActive) return false;
          
          // Check if taken/missed on this date
          if (reminder.takenAt != null) {
            final takenDate = reminder.takenAt!;
            if (takenDate.year == _selectedDate.year &&
                takenDate.month == _selectedDate.month &&
                takenDate.day == _selectedDate.day) {
              return true;
            }
          }
          
          if (reminder.missedAt != null) {
            final missedDate = reminder.missedAt!;
            if (missedDate.year == _selectedDate.year &&
                missedDate.month == _selectedDate.month &&
                missedDate.day == _selectedDate.day) {
              return true;
            }
          }
          
          // Check if created on this date
          final reminderDate = reminder.createdAt;
          return reminderDate.year == _selectedDate.year &&
              reminderDate.month == _selectedDate.month &&
              reminderDate.day == _selectedDate.day;
        }).toList();
        
        final takenCount = allReminders.where((r) => r.status == ReminderStatus.taken).length;
        final missedCount = allReminders.where((r) => r.status == ReminderStatus.missed).length;
        final totalCount = allReminders.length;
        
        return Container(
          margin: const EdgeInsets.all(AppSizes.paddingL),
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
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  totalCount.toString(),
                  AppColors.primary,
                  Icons.medication,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Taken',
                  takenCount.toString(),
                  AppColors.success,
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Missed',
                  missedCount.toString(),
                  AppColors.error,
                  Icons.cancel,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.heading2.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList() {
    return Consumer<ReminderProvider>(
      builder: (context, reminderProvider, child) {
        // Get all reminders including taken and missed ones
        final allReminders = reminderProvider.reminders
            .where((r) => r.isActive)
            .toList();
        
        // Filter by date
        final dateFilteredReminders = allReminders.where((reminder) {
          // Check if reminder matches the selected date
          final reminderDate = reminder.createdAt;
          final isSameDay = reminderDate.year == _selectedDate.year &&
              reminderDate.month == _selectedDate.month &&
              reminderDate.day == _selectedDate.day;
          
          // Also check if taken/missed on this date
          if (reminder.takenAt != null) {
            final takenDate = reminder.takenAt!;
            if (takenDate.year == _selectedDate.year &&
                takenDate.month == _selectedDate.month &&
                takenDate.day == _selectedDate.day) {
              return true;
            }
          }
          
          if (reminder.missedAt != null) {
            final missedDate = reminder.missedAt!;
            if (missedDate.year == _selectedDate.year &&
                missedDate.month == _selectedDate.month &&
                missedDate.day == _selectedDate.day) {
              return true;
            }
          }
          
          return isSameDay;
        }).toList();
        
        // Apply status filter
        List<ReminderModel> filteredReminders;
        switch (_selectedFilter) {
          case 'taken':
            filteredReminders = dateFilteredReminders
                .where((r) => r.status == ReminderStatus.taken)
                .toList();
            break;
          case 'missed':
            filteredReminders = dateFilteredReminders
                .where((r) => r.status == ReminderStatus.missed)
                .toList();
            break;
          default:
            filteredReminders = dateFilteredReminders;
        }
        
        // Sort by time
        filteredReminders.sort((a, b) {
          final aTime = a.time.hour * 60 + a.time.minute;
          final bTime = b.time.hour * 60 + b.time.minute;
          return aTime.compareTo(bTime);
        });
        
        if (filteredReminders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No history for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try selecting a different date or filter',
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
          itemCount: filteredReminders.length,
          itemBuilder: (context, index) {
            final reminder = filteredReminders[index];
            return _buildHistoryCard(reminder);
          },
        );
      },
    );
  }

  Widget _buildHistoryCard(ReminderModel reminder) {
    final isTaken = reminder.status == ReminderStatus.taken;
    final isMissed = reminder.status == ReminderStatus.missed;
    final isPending = reminder.status == ReminderStatus.pending;
    final reminderProvider = Provider.of<ReminderProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getStatusColor(reminder.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getStatusIcon(reminder.status),
                color: _getStatusColor(reminder.status),
                size: 26,
              ),
            ),

            title: Text(
              reminder.medicineName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  reminder.dosage,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  'Scheduled: ${reminder.timeString}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                // Show duration if available
                if (reminder.durationDays != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reminder.durationText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                // Show action timestamp
                if (isTaken && reminder.takenAt != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Taken at ${DateFormat('hh:mm a').format(reminder.takenAt!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                if (isMissed && reminder.missedAt != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.cancel_outlined,
                        size: 14,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Missed at ${DateFormat('hh:mm a').format(reminder.missedAt!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Reminder'),
                        content: const Text(
                          'Are you sure you want to delete this reminder?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await reminderProvider.deleteReminder(reminder.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${reminder.medicineName} deleted'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  child: const Icon(Icons.delete, color: Colors.redAccent, size: 22),
                ),
              ],
            ),
            
            // Make card tappable to edit
            onTap: () async {
              final updatedReminder = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditReminderScreen(reminder: reminder),
                ),
              );

              if (updatedReminder != null && context.mounted) {
                // Reset status to pending when rescheduling
                final resetReminder = updatedReminder.copyWith(
                  status: ReminderStatus.pending,
                  takenAt: null,
                  missedAt: null,
                  updatedAt: DateTime.now(),
                );
                
                // Update in provider
                await reminderProvider.updateReminderDirect(resetReminder);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${reminder.medicineName} rescheduled successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
          ),
          
          // Action buttons for pending reminders
          if (isPending) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await reminderProvider.markReminderAsTaken(reminder.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${reminder.medicineName} marked as taken'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Taken'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await reminderProvider.markReminderAsMissed(reminder.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${reminder.medicineName} marked as missed'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Missed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }




  Color _getStatusColor(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.taken:
        return AppColors.success;
      case ReminderStatus.missed:
        return AppColors.error;
      case ReminderStatus.snoozed:
        return AppColors.warning;
      case ReminderStatus.pending:
        return AppColors.primary;
      case ReminderStatus.completed:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.taken:
        return Icons.check_circle;
      case ReminderStatus.missed:
        return Icons.cancel;
      case ReminderStatus.snoozed:
        return Icons.snooze;
      case ReminderStatus.pending:
        return Icons.access_time;
      case ReminderStatus.completed:
        return Icons.check_circle_outline;
    }
  }

  String _getStatusText(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.taken:
        return 'Taken';
      case ReminderStatus.missed:
        return 'Missed';
      case ReminderStatus.snoozed:
        return 'Snoozed';
      case ReminderStatus.pending:
        return 'Pending';
      case ReminderStatus.completed:
        return 'Completed';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showHistoryDetailsDialog(BuildContext context, ReminderModel reminder) {
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
            Text('Status: ${_getStatusText(reminder.status)}'),
            if (reminder.takenAt != null)
              Text('Taken at: ${DateFormat('dd/MM/yyyy HH:mm').format(reminder.takenAt!)}'),
            if (reminder.missedAt != null)
              Text('Missed at: ${DateFormat('dd/MM/yyyy HH:mm').format(reminder.missedAt!)}'),
            Text('Created: ${DateFormat('dd/MM/yyyy').format(reminder.createdAt)}'),
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
