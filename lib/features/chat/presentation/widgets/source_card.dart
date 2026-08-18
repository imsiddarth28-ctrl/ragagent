import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../models/message_model.dart';

class SourceCard extends StatelessWidget {
  final Source source;

  const SourceCard({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWeb = source.isWeb;

    final bgColor = isWeb 
        ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFECFDF5))
        : (isDark ? const Color(0xFF312E81).withValues(alpha: 0.4) : AppColors.primaryTint);

    final borderColor = isWeb 
        ? const Color(0xFF10B981).withValues(alpha: 0.3)
        : AppColors.primary.withValues(alpha: 0.2);

    final iconColor = isWeb ? const Color(0xFF059669) : AppColors.primary;
    final textColor = isWeb 
        ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46))
        : (isDark ? const Color(0xFFA5B4FC) : AppColors.primaryDark);

    String displayText;
    if (isWeb) {
      final host = source.url != null ? Uri.tryParse(source.url!)?.host : null;
      displayText = host != null && host.isNotEmpty ? host : (source.title ?? 'Web Source');
    } else {
      displayText = '${source.documentName} • p.${source.page}';
    }

    return Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.s),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showSourceModal(context, isWeb),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isWeb ? Icons.public_rounded : Icons.description_rounded, 
                size: 14, 
                color: iconColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  displayText,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSourceModal(BuildContext context, bool isWeb) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isWeb ? Icons.public_rounded : Icons.description_rounded,
                    color: isWeb ? const Color(0xFF059669) : AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isWeb ? (source.title ?? 'Web Source') : source.documentName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (isWeb && source.url != null) ...[
                const SizedBox(height: 6),
                SelectableText(
                  source.url!,
                  style: const TextStyle(color: Color(0xFF2563EB), fontSize: 13, decoration: TextDecoration.underline),
                ),
              ] else if (!isWeb) ...[
                const SizedBox(height: 4),
                Text(
                  'Page ${source.page}',
                  style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                ),
              ],
              const Divider(height: 24),
              const Text('Source Context & Snippet:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Text(
                  source.snippet.isNotEmpty ? source.snippet : 'No snippet preview available.',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
            ],
          ),
        );
      },
    );
  }
}
