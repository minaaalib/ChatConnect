import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/chat_session.dart';
import '../../services/chat_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/clay.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_chip.dart';
import '../../widgets/gradient_background.dart';

class KaiHubScreen extends StatelessWidget {
  const KaiHubScreen({super.key});

  static const _features = [
    ('Calm Me', PhosphorIconsFill.drop),
    ('Journal', PhosphorIconsFill.notePencil),
    ('Goals', PhosphorIconsFill.cursorClick),
    ('Insights', PhosphorIconsFill.chartLineUp),
  ];

  static const _topics = [
    'Anxiety',
    'Depression',
    'Stress',
    'Sleep',
    'Relationships',
    'Academic',
  ];

  static const _capabilities = [
    'Active listening and emotional support',
    'CBT-based coping techniques',
    'Breathing and mindfulness exercises',
    'Mood tracking and insights',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
            children: [
              GlassCard(
                borderRadius: 24,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.surfaceTint,
                          backgroundImage: AssetImage('assets/pfp.png'),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              PhosphorIconsFill.heart,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Hi, I'm Kai",
                      style: textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your personal mental health companion. I\'m here to '
                      'listen, support, and guide you through your '
                      'wellbeing journey.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        for (final f in _features)
                          _FeatureTile(label: f.$1, icon: f.$2),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'GETTING STARTED',
                style: textTheme.labelMedium?.copyWith(
                  letterSpacing: 2,
                  color: AppColors.secondary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              _HubListTile(
                icon: PhosphorIconsFill.chatCircle,
                label: 'Start a new conversation',
                onTap: () => context.go('/chat/session-kai-main'),
              ),
              const SizedBox(height: 12),
              _HubListTile(
                icon: PhosphorIconsFill.clockCounterClockwise,
                label: 'Continue previous session',
                onTap: () => context.go('/chat/session-kai-main'),
              ),
              const SizedBox(height: 12),
              _HubListTile(
                icon: PhosphorIconsFill.firstAidKit,
                label: 'Crisis support',
                highlight: true,
                onTap: () {},
              ),
              const SizedBox(height: 24),
              Text(
                'COMMON TOPICS',
                style: textTheme.labelMedium?.copyWith(
                  letterSpacing: 2,
                  color: AppColors.secondary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _topics.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => GlassChip(label: _topics[i]),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'RESUME ACTIVITY',
                style: textTheme.labelMedium?.copyWith(
                  letterSpacing: 2,
                  color: AppColors.secondary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yesterday',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You discussed anxiety coping strategies with focus '
                      'on 4-7-8 breathing.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/chat/session-kai-main'),
                        icon: const Icon(PhosphorIconsFill.arrowRight),
                        label: const Text('Resume chat'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'RECENT SESSIONS',
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
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          PhosphorIconsFill.sealCheck,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'What I can help with:',
                          style: textTheme.headlineSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    for (final c in _capabilities)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              PhosphorIconsFill.checkCircle,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(c, style: textTheme.bodyMedium),
                            ),
                          ],
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

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.claySurface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: clayShadows(0.6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 26),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _HubListTile extends StatelessWidget {
  const _HubListTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    if (highlight) {
      return Material(
        color: AppColors.tertiaryFixedDim,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onErrorContainer,
                    ),
                  ),
                ),
                Icon(
                  PhosphorIconsFill.arrowRight,
                  color: AppColors.onErrorContainer,
                ),
              ],
            ),
          ),
        ),
      );
    }
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
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(label)),
              const Icon(
                PhosphorIconsBold.caretRight,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
