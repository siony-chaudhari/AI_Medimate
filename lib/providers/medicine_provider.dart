import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/medicine_model.dart';

class MedicineProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<MedicineModel> _medicines = [];
  List<MedicineModel> _expiredMedicines = [];
  List<MedicineModel> _expiringSoonMedicines = [];
  List<MedicineModel> _safeMedicines = [];
  bool _isLoading = false;
  String? _error;

  List<MedicineModel> get medicines => _medicines;
  List<MedicineModel> get expiredMedicines => _expiredMedicines;
  List<MedicineModel> get expiringSoonMedicines => _expiringSoonMedicines;
  List<MedicineModel> get safeMedicines => _safeMedicines;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MedicineProvider() {
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    try {
      _isLoading = true;
      notifyListeners();

      final querySnapshot = await _firestore
          .collection('medicines')
          .orderBy('expiryDate')
          .get();

      _medicines = querySnapshot.docs
          .map((doc) => MedicineModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      _categorizeMedicines();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load medicines: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _categorizeMedicines() {
    _expiredMedicines = _medicines.where((m) => m.isExpired).toList();
    _expiringSoonMedicines = _medicines.where((m) => m.isExpiringSoon).toList();
    _safeMedicines = _medicines.where((m) => m.isSafe).toList();
  }

  Future<bool> addMedicine({
    required String name,
    required String dosage,
    required DateTime expiryDate,
    String? description,
    DateTime? manufacturedDate,
    String? batchNumber,
    String? manufacturer,
    String? imageUrl,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final medicine = MedicineModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        dosage: dosage,
        description: description,
        expiryDate: expiryDate,
        manufacturedDate: manufacturedDate,
        batchNumber: batchNumber,
        manufacturer: manufacturer,
        imageUrl: imageUrl,
        status: _getMedicineStatus(expiryDate),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('medicines')
          .doc(medicine.id)
          .set(medicine.toJson());

      _medicines.add(medicine);
      _categorizeMedicines();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add medicine: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMedicine({
    required String id,
    String? name,
    String? dosage,
    DateTime? expiryDate,
    String? description,
    DateTime? manufacturedDate,
    String? batchNumber,
    String? manufacturer,
    String? imageUrl,
  }) async {
    try {
      final index = _medicines.indexWhere((m) => m.id == id);
      if (index == -1) return false;

      final updatedMedicine = _medicines[index].copyWith(
        name: name,
        dosage: dosage,
        expiryDate: expiryDate,
        description: description,
        manufacturedDate: manufacturedDate,
        batchNumber: batchNumber,
        manufacturer: manufacturer,
        imageUrl: imageUrl,
        status: expiryDate != null ? _getMedicineStatus(expiryDate) : null,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('medicines')
          .doc(id)
          .update(updatedMedicine.toJson());

      _medicines[index] = updatedMedicine;
      _categorizeMedicines();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update medicine: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMedicine(String id) async {
    try {
      await _firestore.collection('medicines').doc(id).delete();
      
      _medicines.removeWhere((m) => m.id == id);
      _categorizeMedicines();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete medicine: $e';
      notifyListeners();
      return false;
    }
  }

  MedicineStatus _getMedicineStatus(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    
    if (difference < 0) {
      return MedicineStatus.expired;
    } else if (difference <= 30) {
      return MedicineStatus.expiringSoon;
    } else {
      return MedicineStatus.safe;
    }
  }

  List<MedicineModel> searchMedicines(String query) {
    if (query.isEmpty) return _medicines;
    
    return _medicines.where((medicine) {
      return medicine.name.toLowerCase().contains(query.toLowerCase()) ||
             medicine.description?.toLowerCase().contains(query.toLowerCase()) == true ||
             medicine.manufacturer?.toLowerCase().contains(query.toLowerCase()) == true;
    }).toList();
  }

  List<MedicineModel> getMedicinesByStatus(MedicineStatus status) {
    switch (status) {
      case MedicineStatus.expired:
        return _expiredMedicines;
      case MedicineStatus.expiringSoon:
        return _expiringSoonMedicines;
      case MedicineStatus.safe:
        return _safeMedicines;
    }
  }

  int getTotalMedicinesCount() => _medicines.length;
  int getExpiredMedicinesCount() => _expiredMedicines.length;
  int getExpiringSoonMedicinesCount() => _expiringSoonMedicines.length;
  int getSafeMedicinesCount() => _safeMedicines.length;

  List<MedicineModel> getMedicinesExpiringInDays(int days) {
    final targetDate = DateTime.now().add(Duration(days: days));
    return _medicines.where((medicine) {
      return medicine.expiryDate.isBefore(targetDate) && !medicine.isExpired;
    }).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refreshMedicines() async {
    await _loadMedicines();
  }
}
