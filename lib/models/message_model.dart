class Message {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<Source>? sources;

  Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.sources,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      text: json['content'] ?? json['text'] ?? '',
      isUser: json['role'] == 'user' || (json['isUser'] ?? false),
      timestamp: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      sources: (json['sources'] as List?)?.map((s) => Source.fromJson(s)).toList(),
    );
  }
}

class Source {
  final String documentName;
  final int page;
  final String snippet;

  Source({
    required this.documentName,
    required this.page,
    required this.snippet,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      documentName: json['document_name'] ?? 'Unknown',
      page: json['page_number'] ?? 1,
      snippet: json['snippet'] ?? json['text'] ?? '',
    );
  }
}
