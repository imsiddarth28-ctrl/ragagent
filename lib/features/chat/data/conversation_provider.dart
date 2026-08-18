import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/conversation_model.dart';
import '../../../core/services/api_service.dart';

class ConversationListNotifier extends AutoDisposeAsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() async {
    final apiService = ref.watch(apiServiceProvider);
    return apiService.getConversations();
  }

  Future<void> deleteConversation(String id) async {
    final apiService = ref.read(apiServiceProvider);
    try {
      await apiService.deleteConversation(id);
      ref.invalidateSelf(); // Refresh list
    } catch (e) {
      // Refresh to restore the deleted item since it failed
      ref.invalidateSelf();
    }
  }
}

final conversationListProvider = AsyncNotifierProvider.autoDispose<ConversationListNotifier, List<Conversation>>(() {
  return ConversationListNotifier();
});
