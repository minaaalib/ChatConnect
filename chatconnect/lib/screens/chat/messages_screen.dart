import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/chat_session.dart';
import '../../services/chat_repository.dart';
import '../../services/counselor_chat_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
            children: [
              Text('Messages', style: textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'Who would you like to talk to?',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              _ChatOptionCard(
                title: 'Kai',
                subtitle: 'AI companion · online 24/7',
                badge: 'AI',
                badgeIcon: PhosphorIconsFill.robot,
                avatar: const CircleAvatar(
                  backgroundColor: AppColors.surfaceTint,
                  backgroundImage: AssetImage('assets/pfp.png'),
                ),
                onTap: () => context.go('/chat/session-kai-main'),
              ),
              const SizedBox(height: 12),
              _ChatOptionCard(
                title: context.read<CounselorChatRepository?>() != null
                    ? 'Guidance Office'
                    : 'Ms. Aurine',
                subtitle: 'Licensed counselor · usually replies in a few hours',
                badge: 'Human Counselor',
                badgeIcon: PhosphorIconsFill.sealCheck,
                badgeColor: AppColors.verified,
                badgeContainerColor: AppColors.verifiedContainer,
                avatar: const CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(
                    PhosphorIconsFill.user,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
                onTap: () => context.go('/chat/session-counselor-1'),
              ),
              const SizedBox(height: 28),
              Text(
                'RECENT CONVERSATIONS',
                style: textTheme.labelMedium?.copyWith(
                  letterSpacing: 2,
                  color: AppColors.secondary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder(
                future: context.read<ChatRepository>().getSessions(),
                builder: (context, snapshot) {
                  final sessions = snapshot.data ?? const <ChatSession>[];
                  if (sessions.isEmpty) return const SizedBox.shrink();
                  return GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < sessions.length; i++)
                          InkWell(
                            onTap: () => context.go('/chat/${sessions[i].id}'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: i == sessions.length - 1
                                    ? null
                                    : Border(
                                        bottom: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.4,
                                    ),
                                    backgroundImage:
                                        sessions[i].type == ChatSessionType.ai
                                        ? const AssetImage('assets/pfp.png')
                                        : null,
                                    child:
                                        sessions[i].type == ChatSessionType.ai
                                        ? null
                                        : const Icon(
                                            PhosphorIconsFill.user,
                                            color: AppColors.primary,
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sessions[i].title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          sessions[i].lastMessagePreview,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    PhosphorIconsBold.caretRight,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatOptionCard extends StatelessWidget {
  const _ChatOptionCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeIcon,
    required this.avatar,
    required this.onTap,
    this.badgeColor = AppColors.primary,
    this.badgeContainerColor = AppColors.surfaceTint,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData badgeIcon;
  final Widget avatar;
  final VoidCallback onTap;
  final Color badgeColor;
  final Color badgeContainerColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      borderRadius: 24,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              avatar,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.headlineSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeContainerColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 12, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
