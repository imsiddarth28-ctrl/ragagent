enum DocumentStatus { processing, ready, failed }

class Document {
  final String id;
  final String name;
  final String type;
  final String size;
  final DateTime uploadDate;
  final int? pages;
  final DocumentStatus status;
  final String? storagePath;
  final String sourceType; // 'upload' or 'web'
  final String? url;
  final String? queryThatTriggeredIt;

  Document({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.uploadDate,
    this.pages,
    required this.status,
    this.storagePath,
    this.sourceType = 'upload',
    this.url,
    this.queryThatTriggeredIt,
  });

  bool get isWeb => sourceType == 'web' || url != null;

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      name: json['name'],
      type: json['file_type'] ?? json['type'] ?? (json['source_type'] == 'web' ? 'web' : ''),
      size: _formatSize(json['file_size'] ?? json['size'] ?? 0),
      uploadDate: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      pages: json['page_count'] ?? json['pages'],
      status: _parseStatus(json['status']),
      storagePath: json['storage_path'],
      sourceType: json['source_type'] ?? (json['url'] != null ? 'web' : 'upload'),
      url: json['url'],
      queryThatTriggeredIt: json['query_that_triggered_it'],
    );
  }

  static DocumentStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'ready': return DocumentStatus.ready;
      case 'failed': return DocumentStatus.failed;
      default: return DocumentStatus.processing;
    }
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
