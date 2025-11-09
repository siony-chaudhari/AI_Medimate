import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '/models/medicine_model.dart';
import '/providers/medicine_provider.dart';
import '/utils/constants.dart';
import 'package:ai_medimate/screens/upload_medicine_expiry_screen.dart';


class ExpiryTrackerScreen extends StatefulWidget {
  const ExpiryTrackerScreen({super.key});

  @override
  State<ExpiryTrackerScreen> createState() => _ExpiryTrackerScreenState();
}

class _ExpiryTrackerScreenState extends State<ExpiryTrackerScreen> {
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
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppStrings.expiryTracker,
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTrackingOverview(),
              const SizedBox(height: 32),
              _buildYourMedicinesSection(),
            ],
          ),
        ),
      ),

//ADD new button

      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     _showAddMedicineDialog(context);
      //   },
      //   backgroundColor: AppColors.primary,
      //   child: const Icon(Icons.add, color: Colors.white),
      // ),
    );
  }

  // 🔹 Overview section
  Widget _buildTrackingOverview() {
    return Consumer<MedicineProvider>(
      builder: (context, medicineProvider, child) {
        final total = medicineProvider.getTotalMedicinesCount();
        final expired = medicineProvider.getExpiredMedicinesCount();
        final soon = medicineProvider.getExpiringSoonMedicinesCount();
        final needAttention = expired + soon;

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
                AppStrings.trackingOverview,
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$total ${AppStrings.medicinesMonitored}',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (needAttention > 0) ...[
                    Text(
                      AppStrings.needAttention,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingS,
                        vertical: AppSizes.paddingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppSizes.radiusS),
                      ),
                      child: Text(
                        needAttention.toString(),
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔹 Categories (Expired, Expiring Soon, Safe)
  Widget _buildYourMedicinesSection() {
    final provider = Provider.of<MedicineProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.yourMedicines,
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        _buildMedicineCategory(
          title: 'Expired',
          medicines: provider.expiredMedicines,
          color: AppColors.error,
          icon: Icons.warning,
        ),

        const SizedBox(height: 16),

        _buildMedicineCategory(
          title: 'Expiring Soon',
          medicines: provider.expiringSoonMedicines,
          color: AppColors.warning,
          icon: Icons.schedule,
        ),

        const SizedBox(height: 16),

        _buildMedicineCategory(
          title: 'Safe',
          medicines: provider.safeMedicines,
          color: AppColors.success,
          icon: Icons.check_circle,
        ),
      ],
    );
  }

  // 🔹 Category Card
  Widget _buildMedicineCategory({
    required String title,
    required List<MedicineModel> medicines,
    required Color color,
    required IconData icon,
  }) {
    if (medicines.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingS,
                vertical: AppSizes.paddingXS,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Text(
                medicines.length.toString(),
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...medicines.map((m) => _buildMedicineCard(m, color)),
      ],
    );
  }

  // 🔹 Individual Medicine Card
  // 🔹 Individual Medicine Card
  Widget _buildMedicineCard(MedicineModel medicine, Color categoryColor) {
    final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);

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
            color: categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
          child: Icon(Icons.medication, color: categoryColor, size: 24),
        ),
        title: Text(
          medicine.name,
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
              medicine.dosage,
              style:
              AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              _getExpiryText(medicine),
              style: AppTextStyles.caption.copyWith(
                color: categoryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        // 🔹 Add Delete Icon at Right Corner
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
          // 🗑️ Delete Icon on Top Right
          Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Medicine'),
                  content: Text(
                    'Are you sure you want to delete "${medicine.name}" permanently?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                final success = await medicineProvider.deleteMedicine(medicine.id);

                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${medicine.name} and its reminders deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete ${medicine.name}'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              }
            },
            child: const Icon(Icons.delete, color: Colors.redAccent, size: 22),
          ),
        ),
          ],
        ),  

        // 👇 Tap for editing expiry
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  UploadMedicineExpiryScreen(medicineName: medicine.name),
            ),
          );

          if (result != null && result is String && result.isNotEmpty) {
            final success = await medicineProvider.updateMedicineExpiry(
                medicine.id, result);

            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to update expiry.')),
              );
            }
          }
        },
      ),
    );
  }


  // 🔹 Helper functions
  String _getExpiryText(MedicineModel medicine) {
    if (medicine.isExpired) {
      return 'Exp. ${DateFormat('MM/yyyy').format(medicine.expiryDate)}';
    } else if (medicine.isExpiringSoon) {
      return 'Expires in ${medicine.daysUntilExpiry} days';
    }
    return 'Exp. ${DateFormat('MM/yyyy').format(medicine.expiryDate)}';
  }

  String _getStatusText(MedicineStatus status) {
    switch (status) {
      case MedicineStatus.expired:
        return AppStrings.expired;
      case MedicineStatus.expiringSoon:
        return AppStrings.expiringSoon;
      case MedicineStatus.safe:
        return AppStrings.safe;
    }
  }

  // 🔹 Placeholder
  void _showAddMedicineDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add medicine feature coming soon!')),
    );
  }
}
