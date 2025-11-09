import 'package:flutter/material.dart';
import '/models/reminder_model.dart';

class AddEditReminderScreen extends StatefulWidget {
  final ReminderModel? reminder;
  const AddEditReminderScreen({this.reminder, super.key});

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  int _durationDays = 7;

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    _nameController = TextEditingController(text: r?.medicineName ?? '');
    _dosageController = TextEditingController(text: r?.dosage ?? '');
    if (r != null) {
      _selectedTime = r.time; // ✅ direct use, since model uses TimeOfDay
      _durationDays = r.durationDays ?? 7; // Load existing duration
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Widget _buildDurationChip(int days) {
    final isSelected = _durationDays == days;
    return ChoiceChip(
      label: Text('$days days'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _durationDays = days);
        }
      },
    );
  }

  DateTime _calculateEndDate() {
    return DateTime.now().add(Duration(days: _durationDays));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reminder == null ? 'Add Reminder' : 'Edit Reminder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Medicine Name'),
                validator: (v) => v!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(labelText: 'Dosage'),
                validator: (v) => v!.isEmpty ? 'Enter dosage' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Time: ${_selectedTime.format(context)}'),
                  TextButton(
                    onPressed: _pickTime,
                    child: const Text('Change'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Duration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'How many days should this medicine be taken?',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDurationChip(7),
                  _buildDurationChip(14),
                  _buildDurationChip(30),
                  _buildDurationChip(60),
                  _buildDurationChip(90),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Custom: '),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: _durationDays.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        suffixText: 'days',
                        isDense: true,
                      ),
                      onChanged: (v) {
                        final days = int.tryParse(v);
                        if (days != null && days > 0) {
                          setState(() => _durationDays = days);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Treatment will end on ${_calculateEndDate().toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final now = DateTime.now();
                    final startDate = widget.reminder?.startDate ?? now;
                    final endDate = startDate.add(Duration(days: _durationDays));
                    
                    final newReminder = ReminderModel(
                      id: widget.reminder?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      medicineId: widget.reminder?.medicineId ??
                          _nameController.text,
                      medicineName: _nameController.text,
                      dosage: _dosageController.text,
                      time: _selectedTime, // ✅ TimeOfDay type
                      frequency: widget.reminder?.frequency ??
                          ReminderFrequency.daily,
                      status: widget.reminder?.status ??
                          ReminderStatus.pending,
                      isActive: true,
                      notificationsEnabled:
                      widget.reminder?.notificationsEnabled ?? true,
                      createdAt:
                      widget.reminder?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                      // Duration fields
                      durationDays: _durationDays,
                      startDate: startDate,
                      endDate: endDate,
                      isCompleted: false,
                    );

                    Navigator.pop(context, newReminder);
                  }
                },
                child: const Text('Save Reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
