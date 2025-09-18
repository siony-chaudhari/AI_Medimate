import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/medicine_provider.dart';
import '/models/medicine_model.dart';
import '/utils/constants.dart';
import 'package:intl/intl.dart';

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
              child: Icon(
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
              // Tracking overview
              _buildTrackingOverview(),
              
              const SizedBox(height: 32),
              
              // Your medicines section
              _buildYourMedicinesSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddMedicineDialog(context);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTrackingOverview() {
    return Consumer<MedicineProvider>(
      builder: (context, medicineProvider, child) {
        final totalMedicines = medicineProvider.getTotalMedicinesCount();
        final expiredCount = medicineProvider.getExpiredMedicinesCount();
        final expiringSoonCount = medicineProvider.getExpiringSoonMedicinesCount();
        final needAttentionCount = expiredCount + expiringSoonCount;
        
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
                      '$totalMedicines ${AppStrings.medicinesMonitored}',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (needAttentionCount > 0) ...[
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
                        needAttentionCount.toString(),
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

  Widget _buildYourMedicinesSection() {
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
        
        // Expired medicines
        _buildMedicineCategory(
          title: 'Expired',
          medicines: Provider.of<MedicineProvider>(context, listen: false).expiredMedicines,
          color: AppColors.error,
          icon: Icons.warning,
        ),
        
        const SizedBox(height: 16),
        
        // Expiring soon medicines
        _buildMedicineCategory(
          title: 'Expiring Soon',
          medicines: Provider.of<MedicineProvider>(context, listen: false).expiringSoonMedicines,
          color: AppColors.warning,
          icon: Icons.schedule,
        ),
        
        const SizedBox(height: 16),
        
        // Safe medicines
        _buildMedicineCategory(
          title: 'Safe',
          medicines: Provider.of<MedicineProvider>(context, listen: false).safeMedicines,
          color: AppColors.success,
          icon: Icons.check_circle,
        ),
      ],
    );
  }

  Widget _buildMedicineCategory({
    required String title,
    required List<MedicineModel> medicines,
    required Color color,
    required IconData icon,
  }) {
    if (medicines.isEmpty) {
      return const SizedBox.shrink();
    }
    
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
              child: Icon(
                icon,
                color: color,
                size: 16,
              ),
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
        ...medicines.map((medicine) => _buildMedicineCard(medicine, color)),
      ],
    );
  }

  Widget _buildMedicineCard(MedicineModel medicine, Color categoryColor) {
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
          child: Icon(
            Icons.medication,
            color: categoryColor,
            size: 24,
          ),
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
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
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
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingS,
            vertical: AppSizes.paddingXS,
          ),
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusS),
          ),
          child: Text(
            _getStatusText(medicine.status),
            style: AppTextStyles.caption.copyWith(
              color: categoryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () {
          _showMedicineDetailsDialog(context, medicine);
        },
      ),
    );
  }

  String _getExpiryText(MedicineModel medicine) {
    if (medicine.isExpired) {
      return 'Exp. ${DateFormat('MM/yyyy').format(medicine.expiryDate)}';
    } else if (medicine.isExpiringSoon) {
      return 'Expires in ${medicine.daysUntilExpiry} days';
    } else {
      return 'Exp. ${DateFormat('MM/yyyy').format(medicine.expiryDate)}';
    }
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

  void _showAddMedicineDialog(BuildContext context) {
    // TODO: Implement add medicine dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add medicine feature coming soon!')),
    );
  }

  void _showMedicineDetailsDialog(BuildContext context, MedicineModel medicine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(medicine.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dosage: ${medicine.dosage}'),
            Text('Expiry Date: ${DateFormat('dd/MM/yyyy').format(medicine.expiryDate)}'),
            if (medicine.manufacturer != null)
              Text('Manufacturer: ${medicine.manufacturer}'),
            if (medicine.batchNumber != null)
              Text('Batch: ${medicine.batchNumber}'),
            Text('Status: ${_getStatusText(medicine.status)}'),
            if (medicine.isExpiringSoon)
              Text('Days until expiry: ${medicine.daysUntilExpiry}'),
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
