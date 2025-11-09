import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '/services/ml_service.dart';
import '/models/reminder_model.dart';
import '/models/medicine_model.dart';

class AIService {
  static const String _geminiApiKey = "AIzaSyCCXXs-NCkB0NW3OLlD-4AStZxdN-IRurs"; // replace with real key
  static const String _geminiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=";

  /// Core: Get response from Gemini using all ML insights + user query
  Future<String> getResponse(String userMessage,
      {List<ReminderModel>? reminders, List<MedicineModel>? medicines}) async {
    try {
      // --------------------------------------------------------
      // 🔹 1. Logistic Regression — Current adherence prediction
      // --------------------------------------------------------
      final adherencePrediction = MLService.predictAdherence(
        time: TimeOfDay.now(),
        dayOfWeek: DateTime.now().weekday,
        medicineCount: 2,
        previousAdherence: 0.7,
        reminderFrequency: 2,
      );

      // --------------------------------------------------------
      // 🔹 2. LSTM — Forecast future adherence
      // --------------------------------------------------------
      final pastAdherence = [0.65, 0.7, 0.75, 0.8, 0.83];
      final forecastNext = await MLService.inferLstmForecast(pastAdherence);

      // --------------------------------------------------------
      // 🔹 3. Reinforcement Q-Learning — Optimize next reminder hour
      // --------------------------------------------------------
      final currentHour = TimeOfDay.now().hour;
      final nextBestHour = MLService.suggestQLearningAdjustment(currentHour);

      // --------------------------------------------------------
      // 🔹 4. Clustering — Behavior grouping (based on synthetic data)
      // --------------------------------------------------------
      final clusterData = [
        [8.0, 3.0, 2.0, 0.7, 2.0],
        [14.0, 5.0, 3.0, 0.8, 2.0],
        [20.0, 6.0, 1.0, 0.9, 1.0],
      ];
      final clusterLabels = MLService.kMeansCluster(clusterData, 3);

      // --------------------------------------------------------
      // 🔹 5. Risk Scoring — Side-effect probability estimation
      // --------------------------------------------------------
      final sideEffectRisk = MLService.predictSideEffectRisk(
        age: 45,
        isPediatric: false,
        medicineRiskFactor: 0.6,
        doseMg: 500,
        comorbidityCount: 1,
      );

      // --------------------------------------------------------
      // 🔹 6. Sentiment Analysis — Detect user message tone
      // --------------------------------------------------------
      final sentiment = MLService.analyzeSentiment(userMessage);

      // --------------------------------------------------------
      // 🔹 7. Adherence Insights — From user reminders
      // --------------------------------------------------------
      final insights = reminders != null && reminders.isNotEmpty
          ? MLService.getAdherenceInsights(reminders)
          : {
        'overallAdherence': 0.0,
        'bestTime': 'Morning',
        'worstTime': 'Evening',
        'recommendations': ['No data available'],
      };

      final recs = MLService.getPersonalizedRecommendations(
        adherenceRate: insights['overallAdherence'] ?? 0.0,
        bestTime: insights['bestTime'] ?? 'Morning',
        worstTime: insights['worstTime'] ?? 'Evening',
        medicineCount: 2,
      );

      // --------------------------------------------------------
      // 🔹 8. Compose ML + Context Summary for Gemini
      // --------------------------------------------------------
      final systemPrompt = """
You are MediMate AI, a smart medication management assistant.
Use the ML insights below to respond naturally, personally, and clearly.

📊 ML Insights Summary
--------------------------------
🤖 Adherence Prediction (Logistic Regression): ${(adherencePrediction * 100).toStringAsFixed(1)}%
🔮 Forecasted Adherence (LSTM): ${(forecastNext * 100).toStringAsFixed(1)}%
🕒 Next Optimal Reminder Hour (Q-Learning): $nextBestHour:00 hrs
📈 Behavior Cluster IDs: ${clusterLabels.join(", ")}
⚕️ Side-Effect Risk Score: ${(sideEffectRisk * 100).toStringAsFixed(1)}%
💬 User Sentiment Tone: $sentiment

📅 Adherence Trends
--------------------------------
- Overall Adherence: ${(insights['overallAdherence'] * 100).toStringAsFixed(1)}%
- Best Time: ${insights['bestTime']}
- Worst Time: ${insights['worstTime']}
- Recommendations: ${recs.join(", ")}

🎯 Guidance
--------------------------------
If user shows negative tone, respond empathetically.
If adherence is low, provide motivational and habit-forming strategies.
If side-effect risk is high, advise to consult healthcare provider.
""";

      // --------------------------------------------------------
      // 🔹 9. Send data + user query to Gemini API
      // --------------------------------------------------------
      final body = jsonEncode({
        "contents": [
          {
            "role": "user",
            "parts": [
              {
                "text": "$systemPrompt\n\nUser Question: $userMessage"
              }
            ]
          }
        ]
      });

      final response = await http.post(
        Uri.parse("$_geminiUrl$_geminiApiKey"),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      // --------------------------------------------------------
      // 🔹 10. Return Gemini Response
      // --------------------------------------------------------
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"];
      } else {
        return "⚠️ Gemini API failed: ${response.body}";
      }
    } catch (e) {
      return "⚠️ Error: $e";
    }
  }

  /// Extract structured reminder details from natural text
  Map<String, dynamic>? extractReminderInfo(String message) {
    final lowerMessage = message.toLowerCase();
    final Map<String, dynamic> reminderInfo = {};

    if (lowerMessage.contains("remind") || lowerMessage.contains("set reminder")) {
      if (lowerMessage.contains("morning") || lowerMessage.contains("am")) {
        reminderInfo["time"] = "08:00";
      } else if (lowerMessage.contains("afternoon") || lowerMessage.contains("pm")) {
        reminderInfo["time"] = "14:00";
      } else if (lowerMessage.contains("evening") || lowerMessage.contains("night")) {
        reminderInfo["time"] = "20:00";
      }

      if (lowerMessage.contains("daily") || lowerMessage.contains("every day")) {
        reminderInfo["frequency"] = "daily";
      } else if (lowerMessage.contains("weekly")) {
        reminderInfo["frequency"] = "weekly";
      }
    }

    return reminderInfo.isNotEmpty ? reminderInfo : null;
  }
}


// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import '/services/ml_service.dart';
// import '/models/reminder_model.dart';
// import '/models/medicine_model.dart';
//
// class AIService {
//   static const String _geminiApiKey = "AIzaSyCCXXs-NCkB0NW3OLlD-4AStZxdN-IRurs"; // replace with real key
//   static const String _geminiUrl =
//       "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=";
//
//   /// Core: Get response from Gemini using ML insights + user query
//   Future<String> getResponse(String userMessage,
//       {List<ReminderModel>? reminders, List<MedicineModel>? medicines}) async {
//     try {
//       // Collect ML insights
//       final adherencePrediction = MLService.predictAdherence(
//         time: TimeOfDay.now(),
//         dayOfWeek: DateTime.now().weekday,
//         medicineCount: 2,
//         previousAdherence: 0.7,
//         reminderFrequency: 2,
//       );
//
//       final insights = reminders != null && reminders.isNotEmpty
//           ? MLService.getAdherenceInsights(reminders)
//           : {
//         'overallAdherence': 0.0,
//         'bestTime': 'Morning',
//         'worstTime': 'Evening',
//         'recommendations': ['No data available'],
//       };
//
//       // Personalized recommendations
//       final recs = MLService.getPersonalizedRecommendations(
//         adherenceRate: insights['overallAdherence'] ?? 0.0,
//         bestTime: insights['bestTime'] ?? 'Morning',
//         worstTime: insights['worstTime'] ?? 'Evening',
//         medicineCount: 2,
//       );
//
//       // Build structured context for Gemini
//       final systemPrompt = """
// You are MediMate AI, a medication management assistant.
// Always use ML insights + user input to guide responses.
//
// ML Insights:
// - Adherence Prediction: ${(adherencePrediction * 100).toStringAsFixed(1)}%
// - Overall Adherence: ${(insights['overallAdherence'] * 100).toStringAsFixed(1)}%
// - Best Time: ${insights['bestTime']}
// - Worst Time: ${insights['worstTime']}
// - Recommendations: ${recs.join(", ")}
// """;
//
//       // Build request body
//       final body = jsonEncode({
//         "contents": [
//           {
//             "role": "user",
//             "parts": [
//               {
//                 "text": "$systemPrompt\n\nUser Question: $userMessage"
//               }
//             ]
//           }
//         ]
//       });
//
//
//       // Make Gemini API call
//       final response = await http.post(
//         Uri.parse("$_geminiUrl$_geminiApiKey"),
//         headers: {"Content-Type": "application/json"},
//         body: body,
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return data["candidates"][0]["content"]["parts"][0]["text"];
//       } else {
//         return "⚠️ Gemini API failed: ${response.body}";
//       }
//     } catch (e) {
//       return "⚠️ Error: $e";
//     }
//   }
//
//   /// Extract reminder info from user message
//   Map<String, dynamic>? extractReminderInfo(String message) {
//     final lowerMessage = message.toLowerCase();
//     final Map<String, dynamic> reminderInfo = {};
//
//     if (lowerMessage.contains("remind") || lowerMessage.contains("set reminder")) {
//       if (lowerMessage.contains("morning") || lowerMessage.contains("am")) {
//         reminderInfo["time"] = "08:00";
//       } else if (lowerMessage.contains("afternoon") || lowerMessage.contains("pm")) {
//         reminderInfo["time"] = "14:00";
//       } else if (lowerMessage.contains("evening") || lowerMessage.contains("night")) {
//         reminderInfo["time"] = "20:00";
//       }
//
//       if (lowerMessage.contains("daily") || lowerMessage.contains("every day")) {
//         reminderInfo["frequency"] = "daily";
//       } else if (lowerMessage.contains("weekly")) {
//         reminderInfo["frequency"] = "weekly";
//       }
//     }
//
//     return reminderInfo.isNotEmpty ? reminderInfo : null;
//   }
// }