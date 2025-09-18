import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';
import '../services/ai_service.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AIService _aiService = AIService();
  
  List<ChatMessageModel> _messages = [];
  List<String> _suggestedQuestions = [];
  bool _isLoading = false;
  String? _error;

  List<ChatMessageModel> get messages => _messages;
  List<String> get suggestedQuestions => _suggestedQuestions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ChatProvider() {
    _loadSuggestedQuestions();
    _addWelcomeMessage();
  }

  void _loadSuggestedQuestions() {
    _suggestedQuestions = [
      'Can you remind me about my medication schedule?',
      'What if I miss a dose?',
      'Can I take this with food?',
      'Set reminder for tomorrow',
      'How to store my medicine properly?',
      'Side effects of my medication',
    ];
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: 'Hello! How can I help with your health questions today?',
      type: MessageType.bot,
      status: MessageStatus.delivered,
      timestamp: DateTime.now(),
    );
    
    _messages.add(welcomeMessage);
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Add user message
      final userMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        type: MessageType.user,
        status: MessageStatus.sent,
        timestamp: DateTime.now(),
        userId: 'current_user', // Replace with actual user ID
      );

      _messages.add(userMessage);
      notifyListeners();

      // Get AI response
      final aiResponse = await _aiService.getResponse(content);
      
      final botMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiResponse,
        type: MessageType.bot,
        status: MessageStatus.delivered,
        timestamp: DateTime.now(),
        botResponse: aiResponse,
      );

      _messages.add(botMessage);
      
      // Save to Firestore
      await _saveMessageToFirestore(userMessage);
      await _saveMessageToFirestore(botMessage);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to send message: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendSuggestedQuestion(String question) async {
    await sendMessage(question);
  }

  Future<void> _saveMessageToFirestore(ChatMessageModel message) async {
    try {
      await _firestore
          .collection('chat_messages')
          .doc(message.id)
          .set(message.toJson());
    } catch (e) {
      // Handle error silently for now
      print('Failed to save message to Firestore: $e');
    }
  }

  Future<void> loadChatHistory() async {
    try {
      _isLoading = true;
      notifyListeners();

      final querySnapshot = await _firestore
          .collection('chat_messages')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final history = querySnapshot.docs
          .map((doc) => ChatMessageModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // Add welcome message if no history
      if (history.isEmpty) {
        _addWelcomeMessage();
      } else {
        _messages = history.reversed.toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load chat history: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearChatHistory() async {
    try {
      _messages.clear();
      _addWelcomeMessage();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear chat history: $e';
      notifyListeners();
    }
  }

  void addSystemMessage(String content) {
    final systemMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.system,
      status: MessageStatus.delivered,
      timestamp: DateTime.now(),
    );
    
    _messages.add(systemMessage);
    notifyListeners();
  }

  List<ChatMessageModel> getMessagesByDate(DateTime date) {
    return _messages.where((message) {
      final messageDate = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );
      final targetDate = DateTime(date.year, date.month, date.day);
      return messageDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void dispose() {
    _messages.clear();
    super.dispose();
  }
}
