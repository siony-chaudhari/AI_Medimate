import 'package:intl/intl.dart';

enum MedicineStatus { safe, expiringSoon, expired }

class MedicineModel {
  final String id;
  final String name;
  final String dosage;
  final String? description;
  final DateTime expiryDate;
  final DateTime? manufacturedDate;
  final String? batchNumber;
  final String? manufacturer;
  final String? imageUrl;
  final MedicineStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? intakeStatus;

  MedicineModel({
    required this.id,
    required this.name,
    required this.dosage,
    this.description,
    required this.expiryDate,
    this.manufacturedDate,
    this.batchNumber,
    this.manufacturer,
    this.imageUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.intakeStatus,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    final expiry = DateTime.tryParse(json['expiryDate'] ?? '') ?? DateTime.now();
    return MedicineModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      dosage: json['dosage'] ?? 'N/A',
      description: json['description'],
      expiryDate: expiry,
      manufacturedDate: json['manufacturedDate'] != null
          ? DateTime.tryParse(json['manufacturedDate'])
          : null,
      batchNumber: json['batchNumber'],
      manufacturer: json['manufacturer'],
      imageUrl: json['imageUrl'],
      status: calculateStatus(expiry),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      intakeStatus: json['intakeStatus'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'description': description,
    'expiryDate': expiryDate.toIso8601String(),
    'manufacturedDate': manufacturedDate?.toIso8601String(),
    'batchNumber': batchNumber,
    'manufacturer': manufacturer,
    'imageUrl': imageUrl,
    'status': status.toString().split('.').last,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'intakeStatus': intakeStatus,
  };

  MedicineModel copyWith({
    String? id,
    String? name,
    String? dosage,
    String? description,
    DateTime? expiryDate,
    DateTime? manufacturedDate,
    String? batchNumber,
    String? manufacturer,
    String? imageUrl,
    MedicineStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? intakeStatus,
  }) {
    final newExpiry = expiryDate ?? this.expiryDate;
    return MedicineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      description: description ?? this.description,
      expiryDate: newExpiry,
      manufacturedDate: manufacturedDate ?? this.manufacturedDate,
      batchNumber: batchNumber ?? this.batchNumber,
      manufacturer: manufacturer ?? this.manufacturer,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? calculateStatus(newExpiry),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      intakeStatus: intakeStatus ?? this.intakeStatus,
    );
  }

  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;
  bool get isExpired => daysUntilExpiry < 0;
  bool get isExpiringSoon => daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  bool get isSafe => daysUntilExpiry > 30;

  String get formattedExpiryDate =>
      DateFormat('dd MMM yyyy').format(expiryDate);

  static MedicineStatus calculateStatus(DateTime expiryDate) {
    final now = DateTime.now();
    final diff = expiryDate.difference(now).inDays;
    if (diff < 0) return MedicineStatus.expired;
    if (diff <= 30) return MedicineStatus.expiringSoon;
    return MedicineStatus.safe;
  }
}
