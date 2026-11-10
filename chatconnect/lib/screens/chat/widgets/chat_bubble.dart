import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../models/chat_message.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/clay.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.onQuickReply,
    this.showQuickReplies = true,
  });

  final ChatMessage message;
  final ValueChanged<String> onQuickReply;

  /// False hides this message's quick-reply chips even if it has some —
  /// used so only the most recent message's suggestions stay on screen.
  final bool showQuickReplies;

  @override
  Widget build(BuildContext context) {
    if (message.sender == MessageSender.system) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    final isUser = message.sender == MessageSender.user;
    return Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryContainer.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryContainer,
                  backgroundImage: message.sender == MessageSender.kai
                      ? const AssetImage('assets/pfp.png')
                      : null,
                  child: message.sender == MessageSender.kai
                      ? null
                      : const Icon(
                          PhosphorIconsFill.user,
                          size: 16,
                          color: AppColors.onPrimaryContainer,
                        ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isUser
                      ? AppColors.primaryContainer
                      : AppColors.claySurface,
                  boxShadow: clayShadows(0.4),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(22),
                    topRight: const Radius.circular(22),
                    bottomLeft: Radius.circular(isUser ? 22 : 6),
                    bottomRight: Radius.circular(isUser ? 6 : 22),
                  ),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: isUser ? AppColors.onPrimary : AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (message.quickReplies.isNotEmpty && showQuickReplies) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final reply in message.quickReplies)
                  ActionChip(
                    label: Text(reply, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.surfaceTint,
                    shape: const StadiumBorder(
                      side: BorderSide(color: AppColors.borderSubtle),
                    ),
                    onPressed: () => onQuickReply(reply),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
