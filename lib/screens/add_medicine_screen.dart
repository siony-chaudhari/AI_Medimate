import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/medicine_provider.dart';
import '/providers/reminder_provider.dart';
import '/models/medicine_model.dart';
import '/models/reminder_model.dart';
import '/utils/constants.dart';



class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _daysController = TextEditingController();

  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Prevent multiple clicks
    if (_isLoading) {
      debugPrint("⚠️ Save already in progress, ignoring click");
      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    debugPrint("🔄 Starting medicine save process...");

    try {
      final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);
      final reminderProvider = Provider.of<ReminderProvider>(context, listen: false);

      final name = _nameController.text.trim();
      final dosage = _dosageController.text.trim();
      final days = int.tryParse(_daysController.text) ?? 30;

      debugPrint("📝 Medicine details: $name, $dosage, daily reminder");

      // Check if medicine already exists
      if (medicineProvider.medicineExists(name)) {
        debugPrint("⚠️ Medicine '$name' already exists");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Medicine "$name" already exists!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Calculate expiry date
      final expiryDate = DateTime.now().add(Duration(days: days));

      debugPrint("💊 Adding medicine to database...");
      debugPrint("📊 Current medicines count: ${medicineProvider.medicines.length}");
      
      // Add medicine to database (ONLY ONCE)
      final medicineSuccess = await medicineProvider.addMedicine(
        name: name,
        dosage: dosage,
        expiryDate: expiryDate,
        description: 'Added manually - Duration: $days days',
      );

      if (!medicineSuccess) {
        throw Exception('Failed to add medicine');
      }
      
      debugPrint("✅ Medicine added successfully to database");
      debugPrint("📊 New medicines count: ${medicineProvider.medicines.length}");

      // Create single daily reminder
      debugPrint("🔔 Creating daily reminder for $name");
      debugPrint("📊 Current reminders count: ${reminderProvider.reminders.length}");
      
      // Check if reminder already exists for this medicine and time
      final existingReminder = reminderProvider.reminders.any((r) => 
        r.medicineName.toLowerCase() == name.toLowerCase() && 
        r.time.hour == _selectedTime.hour && 
        r.time.minute == _selectedTime.minute &&
        r.isActive
      );

      bool reminderSuccess = false;
      if (existingReminder) {
        debugPrint("⚠️ Reminder already exists for $name at ${_selectedTime.format(context)}");
        reminderSuccess = true; // Consider it successful since reminder exists
      } else {
        debugPrint("🔔 Creating reminder for $name at ${_selectedTime.format(context)}");
        
        reminderSuccess = await reminderProvider.addReminder(
          medicineId: name,
          medicineName: name,
          dosage: dosage,
          time: _selectedTime,
          frequency: ReminderFrequency.daily,
        );

        if (reminderSuccess) {
          debugPrint("✅ Successfully created reminder for $name");
        } else {
          debugPrint("❌ Failed to create reminder for $name");
        }
      }
      
      debugPrint("📊 New reminders count: ${reminderProvider.reminders.length}");

      if (mounted) {
        if (reminderSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Added $name with daily reminder at ${_selectedTime.format(context)}!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Added $name but failed to create reminder'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint("❌ Error in _saveMedicine: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to add medicine: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add Medicine',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormCard(),
                const SizedBox(height: 24),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
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
            'Medicine Details',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // Medicine Name
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Medicine Name *',
              hintText: 'Enter medicine name',
              prefixIcon: const Icon(Icons.medication),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter medicine name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Dosage
          TextFormField(
            controller: _dosageController,
            decoration: InputDecoration(
              labelText: 'Dosage *',
              hintText: 'e.g., 500mg, 1 tablet',
              prefixIcon: const Icon(Icons.local_pharmacy),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter dosage';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Duration
          TextFormField(
            controller: _daysController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Duration (Days) *',
              hintText: 'e.g., 30',
              prefixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter duration';
              }
              final days = int.tryParse(value);
              if (days == null || days <= 0) {
                return 'Please enter a valid number of days';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Time Selection
          Text(
            'Reminder Time',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _selectTime,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    _selectedTime.format(context),
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () {
          // Extra safety check to prevent multiple clicks
          if (!_isLoading) {
            _saveMedicine();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLoading ? Colors.grey : AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Adding...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              )
            : Text(
                'Add Medicine & Set Reminder',
                style: AppTextStyles.body1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
