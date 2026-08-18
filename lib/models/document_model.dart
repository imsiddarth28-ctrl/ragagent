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

  static DocumentStatus _parseStatus(String? status) {
    switch (status) {
      case 'ready':
        return DocumentStatus.ready;
      case 'failed':
        return DocumentStatus.failed;
      default:
        return DocumentStatus.processing;
    }
  }

  static String _formatSize(dynamic bytes) {
    final int b = bytes is int ? bytes : 0;
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      name: json['name'],
      type: json['file_type'] ?? json['type'] ?? '',
      size: _formatSize(json['file_size'] ?? json['size'] ?? 0),
      uploadDate: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      pages: json['page_count'] ?? json['pages'],
      status: _parseStatus(json['status']),
    );
  }
}
