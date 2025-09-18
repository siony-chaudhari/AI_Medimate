enum MessageType { user, bot, system }
enum MessageStatus { sent, delivered, read, error }

class ChatMessageModel {
  final String id;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final String? userId;
  final String? botResponse;
  final Map<String, dynamic>? metadata;
  final bool isSuggestedQuestion;

  ChatMessageModel({
    required this.id,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.userId,
    this.botResponse,
    this.metadata,
    this.isSuggestedQuestion = false,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.user,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${json['status']}',
        orElse: () => MessageStatus.sent,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId'],
      botResponse: json['botResponse'],
      metadata: json['metadata'],
      isSuggestedQuestion: json['isSuggestedQuestion'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'botResponse': botResponse,
      'metadata': metadata,
      'isSuggestedQuestion': isSuggestedQuestion,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    String? userId,
    String? botResponse,
    Map<String, dynamic>? metadata,
    bool? isSuggestedQuestion,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      botResponse: botResponse ?? this.botResponse,
      metadata: metadata ?? this.metadata,
      isSuggestedQuestion: isSuggestedQuestion ?? this.isSuggestedQuestion,
    );
  }

  bool get isUser => type == MessageType.user;
  bool get isBot => type == MessageType.bot;
  bool get isSystem => type == MessageType.system;
  
  String get timeString {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
