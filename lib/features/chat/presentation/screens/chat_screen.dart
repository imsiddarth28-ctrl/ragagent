import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../../../models/conversation_model.dart';
import '../../../../models/document_model.dart';
import '../../data/chat_provider.dart';
import '../../../settings/data/ai_settings_provider.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Conversation) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(chatProvider.notifier).setConversationId(args.id);
        });
      } else if (args is Document) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(chatProvider.notifier).setInitialDocument(args.id);
        });
      } else {
        // New fresh chat
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(chatProvider.notifier).clearChat();
        });
      }
      _initialized = true;
    }
  }

  void _handleSend() {
    if (_controller.text.isEmpty) return;
    final text = _controller.text;
    _controller.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final aiSettings = ref.watch(aiSettingsProvider);
    final hasKey = aiSettings.selectedProvider != null && 
                   (aiSettings.apiKeys[aiSettings.selectedProvider!]?.trim().isNotEmpty ?? false);

    // Handle errors with notifications
    ref.listen<ChatState>(chatProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (next.messages.length > (previous?.messages.length ?? 0)) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat with AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: hasKey ? AppColors.secondary : AppColors.accent, 
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  aiSettings.selectedModel ?? (hasKey ? 'AI Ready' : 'Key Required'), 
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(chatProvider.notifier).clearChat(), 
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Clear conversation',
          ),
          const SizedBox(width: AppSpacing.s),
        ],
      ),
      body: Column(
        children: [
          if (!hasKey)
            Container(
              margin: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.s, AppSpacing.m, 0),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(AppRadius.m),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.key_rounded, size: 20, color: Color(0xFFB45309)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'AI API Key missing. Set your key to start answering.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/settings'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Configure', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309), fontSize: 12)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: chatState.messages.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.l),
                  itemCount: chatState.messages.length,
                  itemBuilder: (context, index) => ChatBubble(message: chatState.messages[index]),
                ),
          ),
          
          if (chatState.isLoading)
            _buildTypingIndicator(),

          _buildInputArea(chatState.isLoading),
        ],
      ),
    );
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
              child: const Icon(Icons.psychology_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.m),
            const Text(
              'Ask anything about your docs',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimaryLight),
            ),
            const SizedBox(height: AppSpacing.s),
            const Text(
              'Your questions will be answered using semantic RAG context with citations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.l, bottom: AppSpacing.m),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.m),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                SizedBox(width: 8),
                Text(
                  'AI is analyzing documents...',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppColors.inputFillLight,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: TextField(
                  controller: _controller,
                  enabled: !isLoading,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimaryLight),
                  decoration: const InputDecoration(
                    hintText: 'Ask a question about your documents...',
                    hintStyle: TextStyle(color: AppColors.textMutedLight, fontSize: 14),
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Material(
              color: isLoading ? AppColors.borderLight : AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: isLoading ? null : _handleSend,
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
