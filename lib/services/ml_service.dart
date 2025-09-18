import 'dart:math';
import 'package:flutter/material.dart';
import '/models/reminder_model.dart';
import 'dart:math' as math;



class MLService {
  // Simple logistic regression implementation for medication adherence prediction
  static const double _learningRate = 0.01;
  static const int _maxIterations = 1000;
  
  // Feature weights for the model
  static List<double> _weights = [0.0, 0.0, 0.0, 0.0, 0.0];
  
  // Features: [time_of_day, day_of_week, medicine_count, previous_adherence, reminder_frequency]
  
  /// Predict the likelihood of a user taking medication on time
  static double predictAdherence({
    required TimeOfDay time,
    required int dayOfWeek,
    required int medicineCount,
    required double previousAdherence,
    required int reminderFrequency,
  }) {
    final features = _normalizeFeatures([
      time.hour + time.minute / 60.0, // Time of day (0-24)
      dayOfWeek.toDouble(), // Day of week (1-7)
      medicineCount.toDouble(), // Number of medicines
      previousAdherence, // Previous adherence rate (0-1)
      reminderFrequency.toDouble(), // Reminder frequency
    ]);
    
    final prediction = _sigmoid(_dotProduct(_weights, features));
    return prediction.clamp(0.0, 1.0);
  }
  
  /// Train the model with historical data
  static void trainModel(List<Map<String, dynamic>> trainingData) {
    if (trainingData.isEmpty) return;
    
    final features = <List<double>>[];
    final labels = <double>[];
    
    // Prepare training data
    for (final data in trainingData) {
      final time = data['time'] as TimeOfDay;
      final dayOfWeek = data['dayOfWeek'] as int;
      final medicineCount = data['medicineCount'] as int;
      final previousAdherence = data['previousAdherence'] as double;
      final reminderFrequency = data['reminderFrequency'] as int;
      final wasTaken = data['wasTaken'] as bool;
      
      features.add(_normalizeFeatures([
        time.hour + time.minute / 60.0,
        dayOfWeek.toDouble(),
        medicineCount.toDouble(),
        previousAdherence,
        reminderFrequency.toDouble(),
      ]));
      
      labels.add(wasTaken ? 1.0 : 0.0);
    }
    
    // Train using gradient descent
    _trainGradientDescent(features, labels);
  }
  
  /// Get medication adherence insights
  static Map<String, dynamic> getAdherenceInsights(List<ReminderModel> reminders) {
    if (reminders.isEmpty) {
      return {
        'overallAdherence': 0.0,
        'bestTime': 'Morning',
        'worstTime': 'Evening',
        'recommendations': ['No data available'],
      };
    }
    
    final adherenceByTime = <String, List<bool>>{};
    final adherenceByDay = <int, List<bool>>{};
    
    // Group adherence by time and day
    for (final reminder in reminders) {
      final timeKey = _getTimeOfDay(reminder.time);
      final dayKey = reminder.createdAt.weekday;
      
      adherenceByTime.putIfAbsent(timeKey, () => []);
      adherenceByDay.putIfAbsent(dayKey, () => []);
      
      adherenceByTime[timeKey]!.add(reminder.status == ReminderStatus.taken);
      adherenceByDay[dayKey]!.add(reminder.status == ReminderStatus.taken);
    }
    
    // Calculate overall adherence
    final totalTaken = reminders.where((r) => r.status == ReminderStatus.taken).length;
    final overallAdherence = totalTaken / reminders.length;
    
    // Find best and worst times
    String bestTime = 'Morning';
    String worstTime = 'Evening';
    double bestRate = 0.0;
    double worstRate = 1.0;
    
    adherenceByTime.forEach((time, adherence) {
      final rate = adherence.where((taken) => taken).length / adherence.length;
      if (rate > bestRate) {
        bestRate = rate;
        bestTime = time;
      }
      if (rate < worstRate) {
        worstRate = rate;
        worstTime = time;
      }
    });
    
    // Generate recommendations
    final recommendations = <String>[];
    if (overallAdherence < 0.8) {
      recommendations.add('Consider setting more frequent reminders');
    }
    if (worstRate < 0.5) {
      recommendations.add('Try taking medications at $bestTime instead of $worstTime');
    }
    if (recommendations.isEmpty) {
      recommendations.add('Great job! Keep up the good adherence');
    }
    
    return {
      'overallAdherence': overallAdherence,
      'bestTime': bestTime,
      'worstTime': worstTime,
      'recommendations': recommendations,
      'adherenceByTime': adherenceByTime.map((key, value) => MapEntry(key, value.where((taken) => taken).length / value.length)),
      'adherenceByDay': adherenceByDay.map((key, value) => MapEntry(key, value.where((taken) => taken).length / value.length)),
    };
  }
  
  /// Predict optimal reminder timing
  static TimeOfDay predictOptimalTime({
    required List<ReminderModel> userReminders,
    required int medicineCount,
    required double previousAdherence,
  }) {
    if (userReminders.isEmpty) {
      return const TimeOfDay(hour: 9, minute: 0); // Default to 9 AM
    }
    
    // Analyze when user is most likely to take medication
    final adherenceByHour = <int, List<bool>>{};
    
    for (final reminder in userReminders) {
      final hour = reminder.time.hour;
      adherenceByHour.putIfAbsent(hour, () => []);
      adherenceByHour[hour]!.add(reminder.status == ReminderStatus.taken);
    }
    
    // Find hour with best adherence
    int bestHour = 9;
    double bestRate = 0.0;
    
    adherenceByHour.forEach((hour, adherence) {
      final rate = adherence.where((taken) => taken).length / adherence.length;
      if (rate > bestRate) {
        bestRate = rate;
        bestHour = hour;
      }
    });
    
    return TimeOfDay(hour: bestHour, minute: 0);
  }
  
  /// Get personalized recommendations
  static List<String> getPersonalizedRecommendations({
    required double adherenceRate,
    required String bestTime,
    required String worstTime,
    required int medicineCount,
  }) {
    final recommendations = <String>[];
    
    if (adherenceRate < 0.6) {
      recommendations.add('Your adherence rate is low. Consider setting multiple daily reminders.');
      recommendations.add('Try taking medications at $bestTime when you\'re most likely to remember.');
    } else if (adherenceRate < 0.8) {
      recommendations.add('Good progress! Try to be more consistent with your $worstTime medications.');
      recommendations.add('Consider using pill organizers to stay organized.');
    } else {
      recommendations.add('Excellent adherence! Keep up the great work.');
      recommendations.add('Consider helping others improve their medication adherence.');
    }
    
    if (medicineCount > 5) {
      recommendations.add('You have many medications. Consider using a medication management app.');
    }
    
    if (recommendations.length < 3) {
      recommendations.add('Stay hydrated and maintain a healthy lifestyle alongside your medication.');
    }
    
    return recommendations;
  }
  
  // Helper methods
  
  static String _getTimeOfDay(TimeOfDay time) {
    if (time.hour < 12) return 'Morning';
    if (time.hour < 17) return 'Afternoon';
    return 'Evening';
  }

  static List<double> _normalizeFeatures(List<double> features) {
    // Simple min-max normalization
    final minVal = features.reduce((a, b) => math.min(a, b));
    final maxVal = features.reduce((a, b) => math.max(a, b));
    final range = maxVal - minVal;

    if (range == 0) return features.map((f) => 0.5).toList();

    return features.map((f) => (f - minVal) / range).toList();
  }


  static double _sigmoid(double x) {
    return 1 / (1 + exp(-x));
  }
  
  static double _dotProduct(List<double> a, List<double> b) {
    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }
  
  static void _trainGradientDescent(List<List<double>> features, List<double> labels) {
    for (int iteration = 0; iteration < _maxIterations; iteration++) {
      final gradients = List<double>.filled(_weights.length, 0.0);
      
      // Calculate gradients
      for (int i = 0; i < features.length; i++) {
        final prediction = _sigmoid(_dotProduct(_weights, features[i]));
        final error = prediction - labels[i];
        
        for (int j = 0; j < _weights.length; j++) {
          gradients[j] += error * features[i][j];
        }
      }
      
      // Update weights
      for (int j = 0; j < _weights.length; j++) {
        _weights[j] -= _learningRate * gradients[j] / features.length;
      }
    }
  }
  
  /// Reset model weights (useful for testing)
  static void resetModel() {
    _weights = [0.0, 0.0, 0.0, 0.0, 0.0];
  }
  
  /// Get current model weights (useful for debugging)
  static List<double> getModelWeights() {
    return List.from(_weights);
  }
}

