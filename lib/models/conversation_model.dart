import 'message_model.dart';

class Conversation {
  final String id;
  final String title;
  final String? documentUsed;
  final String lastMessage;
  final DateTime updatedAt;
  final List<Message> messages;

  Conversation({
    required this.id,
    required this.title,
    this.documentUsed,
    required this.lastMessage,
    required this.updatedAt,
    required this.messages,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final messages = (json['messages'] as List?)
            ?.map((m) => Message.fromJson(m))
            .toList() ??
        [];
    return Conversation(
      id: json['id'],
      title: json['title'] ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      lastMessage: messages.isNotEmpty ? messages.last.text : '',
      messages: messages,
    );
  }
}
