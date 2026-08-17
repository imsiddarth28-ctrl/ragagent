import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../models/conversation_model.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/conversation_provider.dart';
import '../../../../core/providers/navigation_provider.dart';

class ChatHistoryScreen extends ConsumerWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(conversationListProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: AppSpacing.s),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) => conversations.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final chat = conversations[index];
                        return _buildChatCard(context, ref, chat);
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(navigationIndexProvider.notifier).state = 2; // Go to chat tab
        },
        label: const Text('New Chat'),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildChatCard(BuildContext context, WidgetRef ref, Conversation chat) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      child: InkWell(
        onTap: () {
          ref.read(navigationIndexProvider.notifier).state = 2; // Switch to Chat tab
          // We would also need to tell the ChatNotifier to load this specific conversation
          // but for now, switching tabs is a good start.
        },
        borderRadius: BorderRadius.circular(AppRadius.l),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      chat.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(chat.updatedAt),
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                    onSelected: (val) {
                      if (val == 'delete') {
                        ref.read(conversationListProvider.notifier).deleteConversation(chat.id);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              if (chat.documentUsed != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        chat.documentUsed!,
                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              Text(
                chat.lastMessage,
                style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: AppSpacing.m),
          const Text('No conversations yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: AppSpacing.s),
          Text('Start a new chat to interact with your documents.', style: TextStyle(color: AppColors.textSecondaryLight)),
        ],
      ),
    );
  }
}
