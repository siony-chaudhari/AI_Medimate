import 'package:flutter/material.dart';

enum ReminderStatus { pending, taken, missed, snoozed }
enum ReminderFrequency { daily, weekly, custom }

class ReminderModel {
  final String id;
  final String medicineId;
  final String medicineName;
  final String dosage;
  final TimeOfDay time;
  final ReminderFrequency frequency;
  final List<int>? customDays; // 1=Monday, 7=Sunday
  final ReminderStatus status;
  final DateTime? takenAt;
  final DateTime? missedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ReminderModel({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.dosage,
    required this.time,
    required this.frequency,
    this.customDays,
    required this.status,
    this.takenAt,
    this.missedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    final timeParts = (json['time'] as String).split(':');
    final time = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    return ReminderModel(
      id: json['id'] ?? '',
      medicineId: json['medicineId'] ?? '',
      medicineName: json['medicineName'] ?? '',
      dosage: json['dosage'] ?? '',
      time: time,
      frequency: ReminderFrequency.values.firstWhere(
        (e) => e.toString() == 'ReminderFrequency.${json['frequency']}',
        orElse: () => ReminderFrequency.daily,
      ),
      customDays: json['customDays'] != null 
          ? List<int>.from(json['customDays'])
          : null,
      status: ReminderStatus.values.firstWhere(
        (e) => e.toString() == 'ReminderStatus.${json['status']}',
        orElse: () => ReminderStatus.pending,
      ),
      takenAt: json['takenAt'] != null 
          ? DateTime.parse(json['takenAt']) 
          : null,
      missedAt: json['missedAt'] != null 
          ? DateTime.parse(json['missedAt']) 
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'dosage': dosage,
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'frequency': frequency.toString().split('.').last,
      'customDays': customDays,
      'status': status.toString().split('.').last,
      'takenAt': takenAt?.toIso8601String(),
      'missedAt': missedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  ReminderModel copyWith({
    String? id,
    String? medicineId,
    String? medicineName,
    String? dosage,
    TimeOfDay? time,
    ReminderFrequency? frequency,
    List<int>? customDays,
    ReminderStatus? status,
    DateTime? takenAt,
    DateTime? missedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      time: time ?? this.time,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      status: status ?? this.status,
      takenAt: takenAt ?? this.takenAt,
      missedAt: missedAt ?? this.missedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isDueToday {
    final now = DateTime.now();
    final today = now.weekday;
    
    switch (frequency) {
      case ReminderFrequency.daily:
        return true;
      case ReminderFrequency.weekly:
        return customDays?.contains(today) ?? false;
      case ReminderFrequency.custom:
        return customDays?.contains(today) ?? false;
    }
  }

  bool get isOverdue {
    if (!isDueToday || status != ReminderStatus.pending) return false;
    
    final now = DateTime.now();
    final reminderTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    
    return now.isAfter(reminderTime);
  }

  String get timeString => 
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
