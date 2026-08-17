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
}
