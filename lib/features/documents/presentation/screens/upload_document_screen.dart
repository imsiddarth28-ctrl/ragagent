import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/document_provider.dart';

class UploadDocumentScreen extends ConsumerStatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  ConsumerState<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends ConsumerState<UploadDocumentScreen> {
  // We'll use the uploadProvider to handle the real state
  
  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt'],
      );

      if (result.isNotEmpty) {
        final file = result.first;
        await ref.read(uploadProvider.notifier).upload(file);
      }
    } catch (e) {
      if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Document', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(uploadProvider.notifier).reset();
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          children: [
            uploadState.when(
              data: (doc) => doc == null ? _buildUploadArea() : _buildSuccessState(doc),
              loading: () => _buildProcessingState(),
              error: (err, st) => _buildErrorState(err.toString()),
            ),
            const Spacer(),
            if (!uploadState.isLoading && !uploadState.hasValue || (uploadState.hasValue && uploadState.value == null))
              Text(
                'Supported formats: PDF, TXT, DOCX\nMax file size: No specific limit',
                textAlign: .center,
                style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
              ),
            const SizedBox(height: AppSpacing.l),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadArea() {
    return InkWell(
      onTap: _pickAndUpload,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: const BoxDecoration(
                color: AppColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.l),
            const Text(
              'Choose a file to upload',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimaryLight),
            ),
            const SizedBox(height: AppSpacing.s),
            const Text(
              'Tap anywhere to browse PDF, DOCX, or TXT',
              style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Column(
        children: [
          SizedBox(
            height: 44,
            width: 44,
            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          ),
          SizedBox(height: AppSpacing.l),
          Text(
            'Processing Document...',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimaryLight),
          ),
          SizedBox(height: AppSpacing.s),
          Text(
            'Extracting text, chunking, and indexing into vector database.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(dynamic doc) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.secondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text(
          'Document is ready!',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          'You can now ask questions about "${doc.name}"',
          textAlign: .center,
          style: TextStyle(color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          text: 'Start Chat',
          onPressed: () => Navigator.of(context).pushReplacementNamed('/chat'),
        ),
        const SizedBox(height: AppSpacing.m),
        AppButton(
          text: 'Upload Another',
          isSecondary: true,
          onPressed: () {
            ref.read(uploadProvider.notifier).reset();
          },
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text(
          'Upload Failed',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          error,
          textAlign: .center,
          style: TextStyle(color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          text: 'Try Again',
          onPressed: () {
            ref.read(uploadProvider.notifier).reset();
            _pickAndUpload();
          },
        ),
      ],
    );
  }
}
