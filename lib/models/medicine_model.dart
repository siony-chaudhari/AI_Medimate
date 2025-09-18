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
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      description: json['description'],
      expiryDate: DateTime.parse(json['expiryDate']),
      manufacturedDate: json['manufacturedDate'] != null 
          ? DateTime.parse(json['manufacturedDate']) 
          : null,
      batchNumber: json['batchNumber'],
      manufacturer: json['manufacturer'],
      imageUrl: json['imageUrl'],
      status: MedicineStatus.values.firstWhere(
        (e) => e.toString() == 'MedicineStatus.${json['status']}',
        orElse: () => MedicineStatus.safe,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
    };
  }

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
  }) {
    return MedicineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      description: description ?? this.description,
      expiryDate: expiryDate ?? this.expiryDate,
      manufacturedDate: manufacturedDate ?? this.manufacturedDate,
      batchNumber: batchNumber ?? this.batchNumber,
      manufacturer: manufacturer ?? this.manufacturer,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get daysUntilExpiry {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    return difference;
  }

  bool get isExpired => daysUntilExpiry < 0;
  bool get isExpiringSoon => daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  bool get isSafe => daysUntilExpiry > 30;
}
