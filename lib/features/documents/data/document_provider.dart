import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../models/document_model.dart';
import '../../../core/services/api_service.dart';

class DocumentListNotifier extends StateNotifier<AsyncValue<List<Document>>> {
  final ApiService _apiService;

  DocumentListNotifier(this._apiService) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final docs = await _apiService.getDocuments();
      state = AsyncValue.data(docs);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void addDocument(Document doc) {
    if (state.hasValue) {
      state = AsyncValue.data([...state.value!, doc]);
    }
  }

  Future<void> deleteDocument(String id) async {
    try {
      await _apiService.deleteDocument(id);
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.where((d) => d.id != id).toList());
      }
    } catch (e, st) {
      // Re-throw so the UI can show the error
      state = AsyncValue.error('Failed to delete document: $e', st);
    }
  }
}

final documentListProvider = StateNotifierProvider<DocumentListNotifier, AsyncValue<List<Document>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DocumentListNotifier(apiService);
});

class UploadNotifier extends StateNotifier<AsyncValue<Document?>> {
  final ApiService _apiService;
  final Ref _ref;

  UploadNotifier(this._apiService, this._ref) : super(const AsyncValue.data(null));

  Future<void> upload(PlatformFile file) async {
    state = const AsyncValue.loading();
    try {
      final doc = await _apiService.uploadDocument(file);
      _ref.read(documentListProvider.notifier).addDocument(doc);
      state = AsyncValue.data(doc);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final uploadProvider = StateNotifierProvider<UploadNotifier, AsyncValue<Document?>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return UploadNotifier(apiService, ref);
});
