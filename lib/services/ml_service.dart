// lib/services/ml_service.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '/models/reminder_model.dart';

class MLService {
  // ------------------------ Simple Logistic Regression (existing) ------------------------
  static const double _learningRate = 0.01;
  static const int _maxIterations = 1000;
  static List<double> _weights = [0, 0, 0, 0, 0];

  /// Predict the likelihood of adherence using a sigmoid on a linear model.
  /// Features: [timeOfDay(0-24), dayOfWeek(1-7), medicineCount, previousAdherence (0-1), reminderFrequency]
  static double predictAdherence({
    required TimeOfDay time,
    required int dayOfWeek,
    required int medicineCount,
    required double previousAdherence,
    required int reminderFrequency,
  }) {
    final features = _normalizeFeatures([
      time.hour + time.minute / 60.0,
      dayOfWeek.toDouble(),
      medicineCount.toDouble(),
      previousAdherence,
      reminderFrequency.toDouble(),
    ]);
    final dot = _dotProduct(_weights, features);
    return _sigmoid(dot).clamp(0.0, 1.0);
  }

  static void trainModel(List<Map<String, dynamic>> trainingData) {
    if (trainingData.isEmpty) return;
    final features = <List<double>>[];
    final labels = <double>[];

    for (final data in trainingData) {
      final t = data['time'] as TimeOfDay;
      final dow = data['dayOfWeek'] as int;
      final medCount = data['medicineCount'] as int;
      final prev = data['previousAdherence'] as double;
      final freq = data['reminderFrequency'] as int;
      final taken = (data['wasTaken'] as bool) ? 1.0 : 0.0;

      features.add(_normalizeFeatures([
        t.hour + t.minute / 60.0,
        dow.toDouble(),
        medCount.toDouble(),
        prev,
        freq.toDouble(),
      ]));
      labels.add(taken);
    }
    _trainGradientDescent(features, labels);
  }

  // ------------------------ Time-series forecasting (lightweight) ------------------------
  // In production use a TFLite LSTM model. Here we provide a simple exponential smoothing
  // predictor as a fallback. If you add a TFLite LSTM model, call inferLstmForecast().
  static double forecastNextAdherence(List<double> history, {double alpha = 0.3}) {
    if (history.isEmpty) return 0.7;
    double s = history[0];
    for (int i = 1; i < history.length; i++) {
      s = alpha * history[i] + (1 - alpha) * s;
    }
    return s.clamp(0.0, 1.0);
  }

  // Placeholder for TFLite LSTM inference
  // You must integrate tflite_flutter or tensorflow_lite package and add .tflite model to assets.
  static Future<double> inferLstmForecast(List<double> history) async {
    // TODO: load model and run inference returning prediction (0-1)
    // For now we return exponential smoothing
    return Future.value(forecastNextAdherence(history));
  }

  // ------------------------ Reinforcement Q-learning for reminder optimization ------------------------
  // Very small discrete Q-table for hours 0..23 and actions: earlier, same, later
  static final Map<int, Map<int, double>> _qTable = {}; // hour -> action -> qval
  static const List<int> _actions = [-1, 0, 1]; // shift hours by -1, 0, +1

  static void _initQTable() {
    for (int h = 0; h < 24; h++) {
      _qTable.putIfAbsent(h, () => {for (var a in _actions) a: 0.0});
    }
  }

  static int suggestQLearningAdjustment(int hour) {
    _initQTable();
    final actions = _qTable[hour]!;
    // return action with highest q
    int bestAction = 0;
    double bestVal = double.negativeInfinity;
    actions.forEach((action, val) {
      if (val > bestVal) {
        bestVal = val;
        bestAction = action;
      }
    });
    return (hour + bestAction).clamp(0, 23);
  }

  // Update Q-table after observing reward (1 for taken, 0 for missed)
  static void updateQTable(int hour, int action, double reward,
      {double alpha = 0.2, double gamma = 0.9}) {
    _initQTable();
    final current = _qTable[hour]![action] ?? 0.0;
    final nextHour = (hour + action).clamp(0, 23);
    final nextBest = _qTable[nextHour]!.values.reduce(math.max);
    final updated = current + alpha * (reward + gamma * nextBest - current);
    _qTable[hour]![action] = updated;
  }

  // ------------------------ Clustering (K-means) ------------------------
  // Cluster users/reminder patterns into K clusters using simple features.
  static List<int> kMeansCluster(List<List<double>> data, int k,
      {int maxIter = 100}) {
    if (data.isEmpty) return [];
    final rnd = math.Random();
    final dims = data[0].length;
    final centroids = List.generate(k, (_) => data[rnd.nextInt(data.length)].toList());
    List<int> labels = List.filled(data.length, 0);

    for (int iter = 0; iter < maxIter; iter++) {
      // assign
      bool changed = false;
      for (int i = 0; i < data.length; i++) {
        double bestDist = double.infinity;
        int bestIdx = 0;
        for (int c = 0; c < k; c++) {
          final dist = _euclideanDistance(data[i], centroids[c]);
          if (dist < bestDist) {
            bestDist = dist;
            bestIdx = c;
          }
        }
        if (labels[i] != bestIdx) {
          labels[i] = bestIdx;
          changed = true;
        }
      }
      if (!changed) break;

      // update centroids
      for (int c = 0; c < k; c++) {
        final members = <List<double>>[];
        for (int i = 0; i < data.length; i++) {
          if (labels[i] == c) members.add(data[i]);
        }
        if (members.isNotEmpty) {
          centroids[c] = List.generate(dims, (d) {
            double sum = 0;
            for (var m in members) sum += m[d];
            return sum / members.length;
          });
        }
      }
    }
    return labels;
  }

  // ------------------------ Side-effect / Risk scoring ------------------------
  // A lightweight risk score using logistic regression-like scoring on structured features.
  // Input features example: age (years), isPediatric (0/1), medicineRiskFactor (0-1), doseMg, comorbidityCount
  static double predictSideEffectRisk({
    required int age,
    required bool isPediatric,
    required double medicineRiskFactor,
    required double doseMg,
    required int comorbidityCount,
  }) {
    // Sample weights (these should be learned from data in production)
    final w = [0.02, 0.5, 1.8, 0.001, 0.4];
    final x = [
      age.toDouble(),
      isPediatric ? 1.0 : 0.0,
      medicineRiskFactor,
      doseMg,
      comorbidityCount.toDouble()
    ];
    double z = 0.0;
    for (int i = 0; i < w.length; i++) z += w[i] * x[i];
    final prob = _sigmoid(z / 10.0); // scaling
    return prob.clamp(0.0, 1.0);
  }

  // ------------------------ Sentiment Analysis (lexicon) ------------------------
  // Very small lexicon-based sentiment analyzer for chat tone detection.
  static const List<String> _posWords = ['good', 'great', 'ok', 'thanks', 'awesome', 'happy'];
  static const List<String> _negWords = ['bad', 'frustrat', 'angry', 'upset', 'sad', 'hate', 'forget'];

  static String analyzeSentiment(String text) {
    final lower = text.toLowerCase();
    int score = 0;
    for (final w in _posWords) {
      if (lower.contains(w)) score++;
    }
    for (final w in _negWords) {
      if (lower.contains(w)) score--;
    }
    if (score >= 1) return 'positive';
    if (score <= -1) return 'negative';
    return 'neutral';
  }

  // ------------------------ Utility & Insight generation ------------------------
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

    for (final r in reminders) {
      final timeKey = _getTimeOfDay(r.time);
      final dayKey = r.createdAt.weekday;
      adherenceByTime.putIfAbsent(timeKey, () => []);
      adherenceByDay.putIfAbsent(dayKey, () => []);
      adherenceByTime[timeKey]!.add(r.status == ReminderStatus.taken);
      adherenceByDay[dayKey]!.add(r.status == ReminderStatus.taken);
    }

    final total = reminders.length;
    final taken = reminders.where((r) => r.status == ReminderStatus.taken).length;
    final overall = total == 0 ? 0.0 : taken / total;

    String best = 'Morning';
    String worst = 'Evening';
    double bestRate = -1.0, worstRate = 2.0;

    adherenceByTime.forEach((k, v) {
      final rate = v.where((t) => t).length / v.length;
      if (rate > bestRate) {
        bestRate = rate;
        best = k;
      }
      if (rate < worstRate) {
        worstRate = rate;
        worst = k;
      }
    });

    final recs = <String>[];
    if (overall < 0.6) {
      recs.add('Set more frequent reminders');
      recs.add('Use pill organizer or link reminders to daily routine');
    } else if (overall < 0.8) {
      recs.add('Try small habit nudges around $worst');
    } else {
      recs.add('Excellent adherence — keep it up!');
    }

    if (recs.length < 2) recs.add('Stay hydrated and follow provider instructions');

    return {
      'overallAdherence': overall,
      'bestTime': best,
      'worstTime': worst,
      'recommendations': recs,
      'adherenceByTime': adherenceByTime.map((k, v) => MapEntry(k, v.where((t) => t).length / v.length)),
      'adherenceByDay': adherenceByDay.map((k, v) => MapEntry(k, v.where((t) => t).length / v.length)),
    };
  }

  static TimeOfDay predictOptimalTime({
    required List<ReminderModel> userReminders,
    required int medicineCount,
    required double previousAdherence,
  }) {
    if (userReminders.isEmpty) return const TimeOfDay(hour: 9, minute: 0);

    final adherenceByHour = <int, List<bool>>{};
    for (final r in userReminders) {
      final h = r.time.hour;
      adherenceByHour.putIfAbsent(h, () => []);
      adherenceByHour[h]!.add(r.status == ReminderStatus.taken);
    }

    int bestHour = 9;
    double bestRate = -1.0;
    adherenceByHour.forEach((hour, arr) {
      final rate = arr.where((t) => t).length / arr.length;
      if (rate > bestRate) {
        bestRate = rate;
        bestHour = hour;
      }
    });

    // Optionally use Q-learning suggestion
    final qSuggested = suggestQLearningAdjustment(bestHour);
    return TimeOfDay(hour: qSuggested, minute: 0);
  }

  static List<String> getPersonalizedRecommendations({
    required double adherenceRate,
    required String bestTime,
    required String worstTime,
    required int medicineCount,
  }) {
    final rec = <String>[];
    if (adherenceRate < 0.6) {
      rec.add('Your adherence is low. Set multiple daily reminders.');
      rec.add('Try taking medications at $bestTime.');
    } else if (adherenceRate < 0.8) {
      rec.add('Good progress. Focus on $worstTime doses.');
      rec.add('Use pill organizers.');
    } else {
      rec.add('Excellent adherence!');
    }
    if (medicineCount > 5) rec.add('You have many meds — consult a pharmacist for simplification.');
    if (rec.length < 3) rec.add('Maintain healthy lifestyle and hydration.');
    return rec;
  }

  // ------------------------ helpers ------------------------
  static String _getTimeOfDay(TimeOfDay t) {
    if (t.hour < 12) return 'Morning';
    if (t.hour < 17) return 'Afternoon';
    return 'Evening';
  }

  static double _sigmoid(double x) => 1 / (1 + math.exp(-x));

  static double _dotProduct(List<double> a, List<double> b) {
    double s = 0.0;
    for (int i = 0; i < a.length && i < b.length; i++) s += a[i] * b[i];
    return s;
  }

  static List<double> _normalizeFeatures(List<double> features) {
    // min-max normalize
    final minVal = features.reduce(math.min);
    final maxVal = features.reduce(math.max);
    final range = maxVal - minVal;
    if (range == 0) return features.map((_) => 0.5).toList();
    return features.map((f) => (f - minVal) / range).toList();
  }

  static void _trainGradientDescent(List<List<double>> features, List<double> labels) {
    for (int it = 0; it < _maxIterations; it++) {
      final grads = List<double>.filled(_weights.length, 0.0);
      for (int i = 0; i < features.length; i++) {
        final pred = _sigmoid(_dotProduct(_weights, features[i]));
        final err = pred - labels[i];
        for (int j = 0; j < _weights.length; j++) grads[j] += err * features[i][j];
      }
      for (int j = 0; j < _weights.length; j++) {
        _weights[j] -= _learningRate * grads[j] / features.length;
      }
    }
  }

  static double _euclideanDistance(List<double> a, List<double> b) {
    double s = 0.0;
    for (int i = 0; i < a.length; i++) s += math.pow(a[i] - b[i], 2).toDouble();
    return math.sqrt(s);
  }

  // Helpful small utility to compute overall adherence safely
  static double safeOverallAdherence(List<ReminderModel> reminders) {
    if (reminders.isEmpty) return 0.0;
    final total = reminders.length;
    final taken = reminders.where((r) => r.status == ReminderStatus.taken).length;
    return taken / total;
  }

  // expose for other files (not private) if needed
  static List<double> getModelWeights() => List.from(_weights);
  static void resetModel() => _weights = [0, 0, 0, 0, 0];
}
