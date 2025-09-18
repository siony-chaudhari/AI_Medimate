import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/reminder_provider.dart';
import '/models/reminder_model.dart';
import '/utils/constants.dart';
import 'package:intl/intl.dart';

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
        final allReminders = reminderProvider.getRemindersForDate(_selectedDate);
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
        final allReminders = reminderProvider.getRemindersForDate(_selectedDate);
        List<ReminderModel> filteredReminders;
        
        switch (_selectedFilter) {
          case 'taken':
            filteredReminders = allReminders.where((r) => r.status == ReminderStatus.taken).toList();
            break;
          case 'missed':
            filteredReminders = allReminders.where((r) => r.status == ReminderStatus.missed).toList();
            break;
          default:
            filteredReminders = allReminders;
        }
        
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
            color: _getStatusColor(reminder.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          child: Icon(
            _getStatusIcon(reminder.status),
            color: _getStatusColor(reminder.status),
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
            if (isTaken && reminder.takenAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Taken at ${DateFormat('HH:mm').format(reminder.takenAt!)}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (isMissed && reminder.missedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Missed at ${DateFormat('HH:mm').format(reminder.missedAt!)}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingS,
            vertical: AppSizes.paddingXS,
          ),
          decoration: BoxDecoration(
            color: _getStatusColor(reminder.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Text(
            _getStatusText(reminder.status),
            style: AppTextStyles.caption.copyWith(
              color: _getStatusColor(reminder.status),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () {
          _showHistoryDetailsDialog(context, reminder);
        },
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
