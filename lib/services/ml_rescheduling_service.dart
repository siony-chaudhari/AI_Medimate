import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ML-powered rescheduling service for missed medications
class MLReschedulingService {
  static final MLReschedulingService _instance = MLReschedulingService._internal();
  factory MLReschedulingService() => _instance;
  MLReschedulingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ML Model parameters
  Map<String, dynamic> _userBehaviorModel = {
    'preferred_times': <int>[],
    'miss_patterns': <String, int>{},
    'success_intervals': <int>[],
    'medicine_adherence': <String, double>{},
  };

  /// Initialize ML service
  Future<void> initialize() async {
    try {
      await _loadUserBehaviorData();
      print("✅ ML Rescheduling Service initialized");
    } catch (e) {
      print("❌ Error initializing ML service: $e");
    }
  }

  /// Load historical user behavior data
  Future<void> _loadUserBehaviorData() async {
    try {
      final historyQuery = await _firestore
          .collection('reminder_history')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final behaviorData = <String, dynamic>{
        'preferred_times': <int>[],
        'miss_patterns': <String, int>{},
        'success_intervals': <int>[],
        'medicine_adherence': <String, double>{},
      };

      for (final doc in historyQuery.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
        final medicineName = data['medicineName'] as String?;
        final rescheduledFrom = data['rescheduledFrom'] as Timestamp?;

        if (timestamp != null && medicineName != null) {
          if (status == 'taken') {
            behaviorData['preferred_times'].add(timestamp.hour);
          }

          if (status == 'missed') {
            final dayOfWeek = _getDayOfWeek(timestamp.weekday);
            behaviorData['miss_patterns'][dayOfWeek] = 
                (behaviorData['miss_patterns'][dayOfWeek] ?? 0) + 1;
          }

          if (status == 'taken' && rescheduledFrom != null) {
            final interval = timestamp.difference(rescheduledFrom.toDate()).inHours;
            if (interval > 0 && interval < 24) {
              behaviorData['success_intervals'].add(interval);
            }
          }
        }
      }

      await _calculateAdherenceRates(behaviorData);
      _userBehaviorModel = behaviorData;
      print("📊 Loaded behavior data: ${historyQuery.docs.length} records");
    } catch (e) {
      print("❌ Error loading behavior data: $e");
    }
  }

  /// Calculate adherence rates
  Future<void> _calculateAdherenceRates(Map<String, dynamic> behaviorData) async {
    try {
      final medicineStats = <String, Map<String, int>>{};
      final historyQuery = await _firestore.collection('reminder_history').get();

      for (final doc in historyQuery.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        final medicineName = (data['medicineName'] as String?)?.toLowerCase();

        if (medicineName != null && status != null && (status == 'taken' || status == 'missed')) {
          medicineStats[medicineName] ??= {'taken': 0, 'missed': 0};
          medicineStats[medicineName]![status] = 
              (medicineStats[medicineName]![status] ?? 0) + 1;
        }
      }

      for (final medicine in medicineStats.keys) {
        final taken = medicineStats[medicine]!['taken'] ?? 0;
        final missed = medicineStats[medicine]!['missed'] ?? 0;
        final total = taken + missed;
        if (total > 0) {
          behaviorData['medicine_adherence'][medicine] = taken / total;
        }
      }
    } catch (e) {
      print("❌ Error calculating adherence: $e");
    }
  }

  /// ML prediction for optimal reschedule time
  Future<DateTime?> predictOptimalRescheduleTime({
    required String medicineName,
    required DateTime originalTime,
    required DateTime missedTime,
  }) async {
    try {
      print("🤖 ML Prediction for $medicineName");
      
      final features = _extractFeatures(medicineName, originalTime, missedTime);
      final predictedTime = _applyMLAlgorithm(features, originalTime, missedTime);
      
      print("   Predicted: ${predictedTime.toString()}");
      return predictedTime;
    } catch (e) {
      print("❌ Error in ML prediction: $e");
      return null;
    }
  }

  /// Extract features for ML model
  Map<String, dynamic> _extractFeatures(String medicineName, DateTime originalTime, DateTime missedTime) {
    final now = DateTime.now();
    return {
      'hour_of_day': now.hour,
      'day_of_week': now.weekday,
      'time_since_missed': now.difference(missedTime).inMinutes,
      'original_hour': originalTime.hour,
      'medicine_adherence': _userBehaviorModel['medicine_adherence'][medicineName.toLowerCase()] ?? 0.5,
      'is_weekend': now.weekday >= 6,
      'is_morning': now.hour >= 6 && now.hour < 12,
      'is_evening': now.hour >= 18 && now.hour < 22,
      'user_preferred_times': _userBehaviorModel['preferred_times'] ?? [],
      'miss_pattern_score': _getMissPatternScore(now.weekday),
    };
  }

  /// Apply ML algorithm
  DateTime _applyMLAlgorithm(Map<String, dynamic> features, DateTime originalTime, DateTime missedTime) {
    final now = DateTime.now();
    
    final timeBasedScore = _timeBasedDecisionTree(features);
    final behaviorBasedScore = _behaviorBasedDecisionTree(features);
    final weights = _calculateNeuralWeights(features);
    
    final finalScore = (timeBasedScore * weights['time']!) + 
                      (behaviorBasedScore * weights['behavior']!);
    
    return _scoreToDateTime(finalScore, originalTime, now);
  }

  /// Time-based decision tree
  double _timeBasedDecisionTree(Map<String, dynamic> features) {
    double score = 0.5;
    final currentHour = features['hour_of_day'] as int;
    final timeSinceMissed = features['time_since_missed'] as int;

    if (timeSinceMissed < 120) score += 0.3;

    final preferredTimes = features['user_preferred_times'] as List<int>;
    if (preferredTimes.isNotEmpty) {
      final avgPreferredTime = preferredTimes.reduce((a, b) => a + b) / preferredTimes.length;
      final timeDistance = (currentHour - avgPreferredTime).abs();
      score += (24 - timeDistance) / 24 * 0.2;
    }

    if (currentHour >= 22 || currentHour <= 6) score -= 0.2;

    final originalHour = features['original_hour'] as int;
    if ((originalHour < 12 && currentHour < 12) || 
        (originalHour >= 18 && currentHour >= 18)) {
      score += 0.15;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Behavior-based decision tree
  double _behaviorBasedDecisionTree(Map<String, dynamic> features) {
    double score = 0.5;
    final adherence = features['medicine_adherence'] as double;
    final missPatternScore = features['miss_pattern_score'] as double;
    final isWeekend = features['is_weekend'] as bool;

    score += adherence * 0.2;
    score -= missPatternScore * 0.15;
    if (isWeekend) score += 0.1;
    if (features['is_morning'] == true || features['is_evening'] == true) score += 0.1;

    return score.clamp(0.0, 1.0);
  }

  /// Calculate neural network weights
  Map<String, double> _calculateNeuralWeights(Map<String, dynamic> features) {
    final adherence = features['medicine_adherence'] as double;
    final timeSinceMissed = features['time_since_missed'] as int;

    double timeWeight = 0.6;
    double behaviorWeight = 0.4;

    if (adherence > 0.8) {
      behaviorWeight = 0.6;
      timeWeight = 0.4;
    }

    if (timeSinceMissed < 60) {
      timeWeight = 0.8;
      behaviorWeight = 0.2;
    }

    return {'time': timeWeight, 'behavior': behaviorWeight};
  }

  /// Convert score to DateTime
  DateTime _scoreToDateTime(double score, DateTime originalTime, DateTime now) {
    final intervals = [1, 2, 3, 4, 6, 8, 12];
    final intervalIndex = (score * (intervals.length - 1)).round();
    final selectedInterval = intervals[intervalIndex];

    DateTime targetTime = now.add(Duration(hours: selectedInterval));

    final preferredTimes = _userBehaviorModel['preferred_times'] as List<int>;
    if (preferredTimes.isNotEmpty) {
      final nearestPreferredHour = _findNearestPreferredTime(targetTime.hour, preferredTimes);
      targetTime = DateTime(
        targetTime.year,
        targetTime.month,
        targetTime.day,
        nearestPreferredHour,
        originalTime.minute,
      );
    }

    if (targetTime.isBefore(now)) {
      targetTime = targetTime.add(const Duration(days: 1));
    }

    return targetTime;
  }

  /// Find nearest preferred time
  int _findNearestPreferredTime(int targetHour, List<int> preferredTimes) {
    if (preferredTimes.isEmpty) return targetHour;
    
    int nearest = preferredTimes.first;
    int minDistance = (targetHour - nearest).abs();
    
    for (final hour in preferredTimes) {
      final distance = (targetHour - hour).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearest = hour;
      }
    }
    
    return nearest;
  }

  /// Get miss pattern score
  double _getMissPatternScore(int weekday) {
    final dayName = _getDayOfWeek(weekday);
    final missCount = _userBehaviorModel['miss_patterns'][dayName] ?? 0;
    final totalMisses = (_userBehaviorModel['miss_patterns'] as Map<String, int>)
        .values
        .fold(0, (sum, count) => sum + count);
    return totalMisses > 0 ? missCount / totalMisses : 0.0;
  }

  /// Convert weekday to name
  String _getDayOfWeek(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  /// Record reminder action for ML learning
  Future<void> recordReminderAction({
    required String reminderId,
    required String medicineName,
    required String action,
    required DateTime timestamp,
    DateTime? rescheduledFrom,
  }) async {
    try {
      await _firestore.collection('reminder_history').add({
        'reminderId': reminderId,
        'medicineName': medicineName,
        'status': action,
        'timestamp': Timestamp.fromDate(timestamp),
        'rescheduledFrom': rescheduledFrom != null ? Timestamp.fromDate(rescheduledFrom) : null,
        'createdAt': Timestamp.now(),
      });
      
      print("📊 Recorded $action for $medicineName");
      
      if (Random().nextDouble() < 0.1) {
        await _loadUserBehaviorData();
      }
    } catch (e) {
      print("❌ Error recording action: $e");
    }
  }

  /// Get ML insights
  Map<String, dynamic> getMLInsights() {
    final preferredTimes = _userBehaviorModel['preferred_times'] as List<int>;
    final adherenceRates = _userBehaviorModel['medicine_adherence'] as Map<String, double>;
    final missPatterns = _userBehaviorModel['miss_patterns'] as Map<String, int>;

    return {
      'most_successful_hour': preferredTimes.isNotEmpty 
          ? preferredTimes.reduce((a, b) => a + b) ~/ preferredTimes.length 
          : 9,
      'overall_adherence': adherenceRates.values.isNotEmpty
          ? adherenceRates.values.reduce((a, b) => a + b) / adherenceRates.values.length
          : 0.0,
      'most_missed_day': missPatterns.entries.isNotEmpty
          ? missPatterns.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 'Unknown',
      'total_data_points': preferredTimes.length,
    };
  }
}
