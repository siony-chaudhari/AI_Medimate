import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  static const String _openaiApiKey = 'YOUR_OPENAI_API_KEY'; // Replace with actual API key
  static const String _openaiUrl = 'https://api.openai.com/v1/chat/completions';
  
  // Fallback responses for when API is not available
  static const Map<String, List<String>> _fallbackResponses = {
    'reminder': [
      'I can help you set up medication reminders! You can create custom reminders for each of your medicines. Would you like me to guide you through setting up a reminder for a specific medication?',
      'To set a reminder, go to the Reminders tab and tap the + button. You can set daily, weekly, or custom schedules.',
      'I recommend setting reminders 15 minutes before your scheduled medication time to give you enough time to prepare.',
    ],
    'missed_dose': [
      'If you miss a dose, take it as soon as you remember. However, if it\'s almost time for your next dose, skip the missed dose and continue with your regular schedule. Never take a double dose to make up for a missed one.',
      'Missing a dose occasionally is common. Just continue with your regular schedule and don\'t double up on doses.',
      'If you frequently miss doses, consider setting multiple reminders or adjusting your medication schedule.',
    ],
    'food_interaction': [
      'Some medications should be taken with food to reduce stomach upset, while others work better on an empty stomach. Check your medication label or ask your pharmacist for specific instructions.',
      'Generally, medications that can cause stomach upset should be taken with food. However, some medications are absorbed better on an empty stomach.',
      'If you\'re unsure, it\'s best to consult your healthcare provider or pharmacist about food interactions.',
    ],
    'storage': [
      'Store your medications in a cool, dry place away from direct sunlight and heat. Most medications should be kept at room temperature.',
      'Keep medications in their original containers with the labels intact. Store them out of reach of children and pets.',
      'Some medications require refrigeration. Check the label for specific storage instructions.',
    ],
    'side_effects': [
      'Side effects vary by medication. Common side effects may include nausea, dizziness, or drowsiness. Contact your healthcare provider if you experience severe or persistent side effects.',
      'Most side effects are mild and temporary. However, if you experience severe reactions like difficulty breathing or swelling, seek immediate medical attention.',
      'Keep track of any side effects you experience and discuss them with your healthcare provider during follow-up appointments.',
    ],
    'general': [
      'I\'m here to help with your medication questions! Feel free to ask about reminders, side effects, storage, or any other medication-related concerns.',
      'For specific medical advice, always consult with your healthcare provider or pharmacist.',
      'I can help you manage your medication schedule and provide general information, but I\'m not a substitute for professional medical advice.',
    ],
  };

  Future<String> getResponse(String userMessage) async {
    try {
      // Try to get response from OpenAI API
      if (_openaiApiKey != 'YOUR_OPENAI_API_KEY') {
        final response = await _getOpenAIResponse(userMessage);
        if (response.isNotEmpty) {
          return response;
        }
      }
      
      // Fallback to predefined responses
      return _getFallbackResponse(userMessage);
    } catch (e) {
      // Return fallback response on error
      return _getFallbackResponse(userMessage);
    }
  }

  Future<String> _getOpenAIResponse(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse(_openaiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openaiApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '''You are MediMate AI, a helpful medication management assistant. 
              You help users with medication reminders, dosage information, side effects, storage, 
              and general medication questions. Always provide helpful, accurate information and 
              remind users to consult healthcare providers for specific medical advice. Keep responses 
              concise and friendly.'''
            },
            {
              'role': 'user',
              'content': userMessage,
            },
          ],
          'max_tokens': 150,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List;
        if (choices.isNotEmpty) {
          final message = choices[0]['message'];
          return message['content'] as String;
        }
      }
      
      return '';
    } catch (e) {
      print('OpenAI API error: $e');
      return '';
    }
  }

  String _getFallbackResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    if (message.contains('remind') || message.contains('schedule') || message.contains('reminder')) {
      return _getRandomResponse('reminder');
    } else if (message.contains('miss') || message.contains('forgot') || message.contains('skip')) {
      return _getRandomResponse('missed_dose');
    } else if (message.contains('food') || message.contains('empty stomach') || message.contains('meal')) {
      return _getRandomResponse('food_interaction');
    } else if (message.contains('store') || message.contains('keep') || message.contains('refrigerate')) {
      return _getRandomResponse('storage');
    } else if (message.contains('side effect') || message.contains('reaction') || message.contains('symptom')) {
      return _getRandomResponse('side_effects');
    } else {
      return _getRandomResponse('general');
    }
  }

  String _getRandomResponse(String category) {
    final responses = _fallbackResponses[category] ?? _fallbackResponses['general']!;
    final random = DateTime.now().millisecond % responses.length;
    return responses[random];
  }

  // Method to handle reminder creation from chat
  Map<String, dynamic>? extractReminderInfo(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Simple pattern matching for reminder creation
    if (lowerMessage.contains('remind') || lowerMessage.contains('set reminder')) {
      final Map<String, dynamic> reminderInfo = {};
      
      // Extract time information
      if (lowerMessage.contains('morning') || lowerMessage.contains('am')) {
        reminderInfo['time'] = '08:00';
      } else if (lowerMessage.contains('afternoon') || lowerMessage.contains('pm')) {
        reminderInfo['time'] = '14:00';
      } else if (lowerMessage.contains('evening') || lowerMessage.contains('night')) {
        reminderInfo['time'] = '20:00';
      }
      
      // Extract frequency
      if (lowerMessage.contains('daily') || lowerMessage.contains('every day')) {
        reminderInfo['frequency'] = 'daily';
      } else if (lowerMessage.contains('weekly') || lowerMessage.contains('every week')) {
        reminderInfo['frequency'] = 'weekly';
      } else if (lowerMessage.contains('twice') || lowerMessage.contains('2 times')) {
        reminderInfo['frequency'] = 'custom';
        reminderInfo['customDays'] = [1, 2, 3, 4, 5, 6, 7]; // Daily
      }
      
      return reminderInfo.isNotEmpty ? reminderInfo : null;
    }
    
    return null;
  }
}
