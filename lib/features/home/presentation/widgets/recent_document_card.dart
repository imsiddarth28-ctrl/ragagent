import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../models/document_model.dart';

class RecentDocumentCard extends StatelessWidget {
  final Document document;

  const RecentDocumentCard({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      child: ListTile(
        onTap: () => Navigator.of(context).pushNamed('/document-details', arguments: document),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _getFileColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.m),
          ),
          child: Icon(_getFileIcon(), color: _getFileColor()),
        ),
        title: Text(
          document.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${document.type.toUpperCase()} • ${document.size} • ${DateFormat('MMM dd, yyyy').format(document.uploadDate)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, size: 20),
          onPressed: () {},
        ),
      ),
    );
  }

  IconData _getFileIcon() {
    switch (document.type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'docx':
        return Icons.description_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  Color _getFileColor() {
    switch (document.type.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'docx':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }
}
