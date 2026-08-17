import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/constants/constants.dart';
import '../../../../models/message_model.dart';
import 'source_card.dart';

class ChatBubble extends StatelessWidget {
  final Message message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.l),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) _buildAvatar(false),
              const SizedBox(width: AppSpacing.s),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.m),
                      topRight: Radius.circular(AppRadius.m),
                      bottomLeft: Radius.circular(isUser ? AppRadius.m : 0),
                      bottomRight: Radius.circular(isUser ? 0 : AppRadius.m),
                    ),
                    boxShadow: [
                      if (!isUser)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: isUser 
                    ? Text(
                        message.text,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                      )
                    : MarkdownBody(
                        data: message.text,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                      ),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              if (isUser) _buildAvatar(true),
            ],
          ),
          if (!isUser && message.sources != null && message.sources!.isNotEmpty)
            _buildSources(context),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser ? Colors.grey.shade200 : AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUser ? Icons.person_outline_rounded : Icons.auto_awesome_rounded,
        size: 18,
        color: isUser ? Colors.grey.shade600 : AppColors.primary,
      ),
    );
  }

  Widget _buildSources(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 40, top: AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sources',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: message.sources!.map((source) => SourceCard(source: source)).toList(),
          ),
        ],
      ),
    );
  }
}
