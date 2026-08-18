import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../../../models/document_model.dart';
import '../../../documents/data/document_provider.dart';
import '../widgets/recent_document_card.dart';
import '../widgets/stats_card.dart';

import '../../../../core/providers/navigation_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentListProvider);

    return Scaffold(
      body: SafeArea(
        child: docsAsync.when(
          data: (docs) => _buildContent(context, ref, docs),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => _buildErrorState(context, ref, err.toString()),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.m),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'We couldn\'t load your dashboard. Please check your connection to the backend.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: AppSpacing.l),
            ElevatedButton(
              onPressed: () => ref.read(documentListProvider.notifier).refresh(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<Document> docs) {
    final recentDocs = docs.take(3).toList();
    final totalSize = docs.fold<int>(0, (sum, doc) {
      try {
        if (doc.size.contains('MB')) {
          return sum + (double.parse(doc.size.split(' ')[0]) * 1024 * 1024).toInt();
        }
        if (doc.size.contains('KB')) {
          return sum + (double.parse(doc.size.split(' ')[0]) * 1024).toInt();
        }
        return sum + int.parse(doc.size.split(' ')[0]);
      } catch (_) {
        return sum;
      }
    });

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(documentListProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back 👋',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'AI Workspace',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderLight, width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryTint,
                    child: Icon(Icons.person_rounded, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),

            // AI Assistant Card
            _buildAICard(context),
            const SizedBox(height: AppSpacing.xl),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    label: 'Indexed Files',
                    value: docs.length.toString(),
                    icon: Icons.description_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: StatsCard(
                    label: 'Storage Used',
                    value: _formatBytes(totalSize),
                    icon: Icons.cloud_done_rounded,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Quick Actions
            Row(
              children: [
                _buildQuickAction(
                  context,
                  'Upload Doc',
                  Icons.upload_file_rounded,
                  AppColors.primary,
                  () => Navigator.of(context).pushNamed('/upload'),
                ),
                const SizedBox(width: AppSpacing.m),
                _buildQuickAction(
                  context,
                  'Ask AI Chat',
                  Icons.auto_awesome_rounded,
                  AppColors.secondary,
                  () => Navigator.of(context).pushNamed('/chat'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Recent Documents Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Documents',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimaryLight),
                ),
                if (docs.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      ref.read(navigationIndexProvider.notifier).state = 1;
                    },
                    child: const Text('View all'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            if (docs.isEmpty)
              _buildEmptyDocs(context)
            else
              ...recentDocs.map((doc) => RecentDocumentCard(document: doc)),
            
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildAICard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.m),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppSpacing.s),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'RAG Assistant Active',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          const Text(
            'What would you like to know?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ask anything about your uploaded documents and get grounded answers.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/chat'),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('Start Conversation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(190, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.m),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDocs(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.note_add_rounded, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.m),
          const Text('No documents uploaded yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'Upload a PDF, DOCX, or TXT file to start querying.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.m),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/upload'),
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Upload Document'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(180, 42),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.l),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.m, horizontal: AppSpacing.m),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.m),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimaryLight),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
