import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../models/document_model.dart';
import '../../data/document_provider.dart';

class DocumentDetailsScreen extends ConsumerWidget {
  final Document document;

  const DocumentDetailsScreen({super.key, required this.document});

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(documentListProvider.notifier).deleteDocument(document.id);
              Navigator.pop(context); // Pop dialog
              Navigator.pop(context); // Pop details screen
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Details', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined)),
          IconButton(
            onPressed: () => _showDeleteDialog(context, ref), 
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
          ),
          const SizedBox(width: AppSpacing.s),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: const Icon(Icons.article_rounded, size: 50, color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  Text(
                    document.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      document.status.name.toUpperCase(),
                      style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            
            // Stats
            const Text('Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: AppSpacing.m),
            _buildInfoRow(Icons.type_specimen_outlined, 'File type', document.type.toUpperCase()),
            _buildInfoRow(Icons.straighten_rounded, 'File size', document.size),
            _buildInfoRow(Icons.calendar_today_outlined, 'Upload date', DateFormat('MMM dd, yyyy HH:mm').format(document.uploadDate)),
            _buildInfoRow(Icons.auto_stories_outlined, 'Pages', document.pages?.toString() ?? 'N/A'),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Knowledge Base Info
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppRadius.m),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.textSecondaryLight),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(
                      'This document is indexed and available to the AI assistant for question answering.',
                      style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            AppButton(
              text: 'Chat with this document',
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: () => Navigator.of(context).pushNamed('/chat', arguments: document),
            ),
            const SizedBox(height: AppSpacing.m),
            AppButton(
              text: 'Open Document',
              isSecondary: true,
              icon: Icons.open_in_new_rounded,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondaryLight),
          const SizedBox(width: AppSpacing.m),
          Text(label, style: TextStyle(color: AppColors.textSecondaryLight)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
