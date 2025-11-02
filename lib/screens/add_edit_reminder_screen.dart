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
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Duration (days):'),
                  DropdownButton<int>(
                    value: _durationDays,
                    items: [1, 3, 5, 7, 10, 15, 30]
                        .map((d) => DropdownMenuItem(value: d, child: Text('$d')))
                        .toList(),
                    onChanged: (v) => setState(() => _durationDays = v!),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
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
