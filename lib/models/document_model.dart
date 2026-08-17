enum DocumentStatus { processing, ready, failed }

class Document {
  final String id;
  final String name;
  final String type;
  final String size;
  final DateTime uploadDate;
  final int? pages;
  final DocumentStatus status;

  Document({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.uploadDate,
    this.pages,
    required this.status,
  });
}
