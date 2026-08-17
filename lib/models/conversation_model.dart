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
}
