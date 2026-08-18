import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../models/document_model.dart';

class RecentDocumentCard extends StatelessWidget {
  final Document document;

  const RecentDocumentCard({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 4),
        onTap: () => Navigator.of(context).pushNamed('/document-details', arguments: document),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _getFileColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.m),
          ),
          child: Icon(_getFileIcon(), color: _getFileColor(), size: 24),
        ),
        title: Text(
          document.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimaryLight),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getFileColor().withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  document.type.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getFileColor()),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${document.size} • ${DateFormat('MMM dd').format(document.uploadDate)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMutedLight),
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
        return const Color(0xFFEF4444); // Red 500
      case 'docx':
        return const Color(0xFF2563EB); // Blue 600
      default:
        return const Color(0xFF4F46E5); // Indigo 600
    }
  }
}
