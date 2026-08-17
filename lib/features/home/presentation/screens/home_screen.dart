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
      // Basic size parsing for display purposes
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
                      'Welcome back,',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textSecondaryLight,
                            fontWeight: FontWeight.normal,
                          ),
                    ),
                    Text(
                      'RAG User',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=raguser'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // AI Assistant Card
            _buildAICard(context),
            const SizedBox(height: AppSpacing.xl),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    label: 'Documents',
                    value: docs.length.toString(),
                    icon: Icons.description_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: StatsCard(
                    label: 'Storage',
                    value: _formatBytes(totalSize),
                    icon: Icons.cloud_outlined,
                    color: AppColors.accent,
                  ),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
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
            
            const SizedBox(height: AppSpacing.xl),
            
            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                _buildQuickAction(
                  context,
                  'Upload',
                  Icons.upload_file_rounded,
                  () => Navigator.of(context).pushNamed('/upload'),
                ),
                const SizedBox(width: AppSpacing.m),
                _buildQuickAction(
                  context,
                  'Ask AI',
                  Icons.psychology_rounded,
                  () => Navigator.of(context).pushNamed('/chat'),
                ),
              ],
            ),
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
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
          const SizedBox(height: AppSpacing.m),
          const Text(
            'What would you like to know?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            'Ask anything about your uploaded documents and get instant answers.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushNamed('/chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(180, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.m),
              ),
            ),
            child: const Text('Start a conversation'),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(Icons.description_outlined, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: AppSpacing.s),
          const Text('No documents yet', style: TextStyle(fontWeight: FontWeight.w600)),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/upload'),
            child: const Text('Upload your first file'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.l),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.l),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: AppSpacing.s),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
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
