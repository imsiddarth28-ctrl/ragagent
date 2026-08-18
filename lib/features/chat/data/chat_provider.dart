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
  List<String>? _selectedDocumentIds;

  void setConversationId(String id) {
    _conversationId = id;
    _selectedDocumentIds = null;
    _loadMessages();
  }

  void setInitialDocument(String docId) {
    _conversationId = null;
    _selectedDocumentIds = [docId];
    state = state.copyWith(messages: []);
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

    // 1. Add user message to state immediately
    final userMessage = Message(
      id: DateTime.now().toIso8601String(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    // 2. Check AI Settings for current provider/model/key
    final settings = _ref.read(aiSettingsProvider);
    final provider = settings.selectedProvider;
    final model = settings.selectedModel;
    final apiKey = provider != null ? settings.apiKeys[provider] : null;

    if (provider == null || model == null || apiKey == null || apiKey.trim().isEmpty) {
      final helperMessage = Message(
        id: 'missing_key_${DateTime.now().millisecondsSinceEpoch}',
        text: '⚠️ **AI Provider or API Key Missing**\n\nTo generate answers from your documents, please go to the **Settings** tab, choose your AI Provider (Google Gemini, Groq, or OpenAI), and save your API Key.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, helperMessage],
        isLoading: false,
        error: "Please configure your AI Provider and API Key in Settings.",
      );
      return;
    }

    // 3. Initialize conversation if needed
    try {
      if (_conversationId == null) {
        final title = text.length > 24 ? "${text.substring(0, 24)}..." : text;
        final conv = await _apiService.createConversation(
          title, 
          documentIds: _selectedDocumentIds,
        );
        _conversationId = conv.id;
      }
    } catch (e) {
      final cleanErr = e.toString().replaceAll('Exception: ', '').replaceAll('Network error: ', '');
      final failMessage = Message(
        id: 'conv_err_${DateTime.now().millisecondsSinceEpoch}',
        text: '⚠️ **Could not connect to backend** ($cleanErr)\n\nPlease verify your internet connection or try again in a moment while the server spins up.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, failMessage],
        isLoading: false,
        error: cleanErr,
      );
      return;
    }

    // 4. Call real RAG endpoint
    try {
      final aiMessage = await _apiService.askQuestion(
        conversationId: _conversationId!,
        question: text,
        provider: provider,
        model: model,
        apiKey: apiKey,
        topK: settings.topK,
        allowWebSearch: settings.allowWebSearch,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } catch (e) {
      final cleanError = e.toString().replaceAll('Exception: ', '').replaceAll('RAG Agent error: ', '');
      final errorMessage = Message(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        text: '⚠️ **AI Error**: $cleanError\n\n_Tip: Verify your API key in Settings > AI Configuration or test your connection._',
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
        error: cleanError,
      );
    }
  }

  void clearChat() {
    _conversationId = null;
    _selectedDocumentIds = null;
    state = ChatState(messages: [
      Message(
        id: 'welcome',
        text: 'Hello! I can help you find information in your documents. What would you like to know?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ]);
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ChatNotifier(apiService, ref);
});
