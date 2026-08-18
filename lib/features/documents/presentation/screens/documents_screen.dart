import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../../../models/document_model.dart';
import '../../../home/presentation/widgets/recent_document_card.dart';
import '../../data/document_provider.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  String selectedFilter = 'All';
  final List<String> filters = ['All', 'PDFs', 'Text', 'Recent'];

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentListProvider);

    // Error notification listener
    ref.listen<AsyncValue<List<Document>>>(documentListProvider, (previous, next) {
      if (next is AsyncError && previous is! AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load documents: ${next.error}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: () => ref.read(documentListProvider.notifier).refresh(), icon: const Icon(Icons.refresh_rounded)),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/upload'),
            icon: const Icon(Icons.add_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.s),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.s),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search documents...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
            child: Row(
              children: filters.map((filter) {
                final isSelected = selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        selectedFilter = filter;
                      });
                    },
                    backgroundColor: AppColors.surfaceLight,
                    selectedColor: AppColors.primaryTint,
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.m),
                      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.borderLight),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          
          // Document List
          Expanded(
            child: docsAsync.when(
              data: (docs) {
                final filteredDocs = _filterDocs(docs);
                return filteredDocs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          return RecentDocumentCard(document: doc);
                        },
                      );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, st) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
            ),
          ),
        ],
      ),
    );
  }

  List<Document> _filterDocs(List<Document> docs) {
    if (selectedFilter == 'All') return docs;
    if (selectedFilter == 'PDFs') return docs.where((d) => d.type.toLowerCase() == 'pdf').toList();
    if (selectedFilter == 'Text') return docs.where((d) => d.type.toLowerCase() == 'txt' || d.type.toLowerCase() == 'docx').toList();
    if (selectedFilter == 'Recent') {
      final sorted = List<Document>.from(docs);
      sorted.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
      return sorted;
    }
    return docs;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder_open_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.m),
            const Text(
              'No documents found',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimaryLight),
            ),
            const SizedBox(height: AppSpacing.s),
            const Text(
              'Upload your first document to start chatting with your knowledge base.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.l),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/upload'),
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Upload Document'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
