import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/message_model.dart';
import '../../../core/services/api_service.dart';
import '../../settings/data/ai_settings_provider.dart';

class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;

  ChatState({
    required this.messages,
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ApiService _apiService;
  final Ref _ref;

  ChatNotifier(this._apiService, this._ref) : super(ChatState(messages: [
    Message(
      id: 'welcome',
      text: 'Hello! I can help you find information in your documents. What would you like to know?',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ]));

  String? _conversationId;

  void setConversationId(String id) {
    _conversationId = id;
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (_conversationId == null) return;
    
    state = state.copyWith(isLoading: true);
    try {
      final conversation = await _apiService.getConversation(_conversationId!);
      state = state.copyWith(
        messages: conversation.messages,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Failed to load chat history.",
      );
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Get AI Settings for current provider/model/key
    final settings = _ref.read(aiSettingsProvider);
    final provider = settings.selectedProvider;
    final model = settings.selectedModel;
    final apiKey = provider != null ? settings.apiKeys[provider] : null;

    if (provider == null || model == null || apiKey == null || apiKey.isEmpty) {
      state = state.copyWith(error: "Please configure your AI Provider and API Key in Settings first.");
      return;
    }

    // 2. Initialize conversation if needed
    try {
      if (_conversationId == null) {
        final conv = await _apiService.createConversation("New Chat ${DateTime.now().hour}:${DateTime.now().minute}");
        _conversationId = conv.id;
      }
    } catch (e) {
      state = state.copyWith(error: "Failed to initialize conversation.");
      return;
    }

    // 3. Optimistically add user message
    final userMessage = Message(
      id: DateTime.now().toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      // 4. Call real RAG endpoint
      final aiMessage = await _apiService.askQuestion(
        conversationId: _conversationId!,
        question: text,
        provider: provider,
        model: model,
        apiKey: apiKey,
        topK: settings.topK,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Failed to get an answer from the AI. $e",
      );
    }
  }

  void clearChat() {
    _conversationId = null;
    state = ChatState(messages: []);
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ChatNotifier(apiService, ref);
});
