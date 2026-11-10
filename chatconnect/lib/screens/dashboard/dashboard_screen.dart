import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../constants/mental_health_quotes.dart';
import '../../models/chat_session.dart';
import '../../services/auth_service.dart';
import '../../services/chat_repository.dart';
import '../../services/home_widget_service.dart';
import '../../services/mood_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/apple_emoji.dart';
import '../../widgets/clay.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/interactive_mascot.dart';
import '../../widgets/speech_bubble.dart';
import 'widgets/dashboard_fab.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _moods = [
    ('😊', 'Happy'),
    ('😐', 'Okay'),
    ('😔', 'Sad'),
    ('😡', 'Angry'),
    ('😰', 'Anxious'),
  ];

  /// Lets the dashboard drive the mascot imperatively — e.g.
  /// `_mascotKey.currentState?.playSuccessAnimation();` after a journal
  /// entry saves, or `.startBreathingExercise()` from a calm-down action.
  /// Static (rather than an instance field) so it survives this being a
  /// `const` widget rebuilt by `context.watch` without becoming a new key
  /// each time.
  static final _mascotKey = GlobalKey<InteractiveMascotState>();

  /// Starts the mascot's breathing-exercise animation from outside this
  /// screen — e.g. when Kai hands off a "START_BREATHING" action from chat.
  /// Call shortly after navigating here so the mascot's state has attached.
  static void triggerBreathingExercise() {
    _mascotKey.currentState?.startBreathingExercise();
  }

  /// Maps the dashboard's 5-way mood log onto the mascot's coarser motion
  /// register: Angry reads as wound-up/tense like Anxious rather than the
  /// slow stillness of Heavy, which is reserved for Sad.
  static MascotMood _mascotMoodFor(String? label) => switch (label) {
    'Happy' => MascotMood.peaceful,
    'Sad' => MascotMood.heavy,
    'Angry' || 'Anxious' => MascotMood.anxious,
    _ => MascotMood.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = context.watch<AuthService>().currentUser;
    final mood = context.watch<MoodService>();
    final moodLabel = mood.entries.isEmpty
        ? null
        : mood.entries.first.moodLabel;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          bottom: false,
          // Translucent so it never steals taps/swipes from the content
          // below — it only observes them, to make the mascot (see
          // InteractiveMascotState.lookAt) tilt toward wherever the user
          // touches the screen, simulating it "watching" them.
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) =>
                _mascotKey.currentState?.lookAt(event.position),
            onPointerMove: (event) =>
                _mascotKey.currentState?.lookAt(event.position),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning, ${user?.fullName ?? 'friend'}!',
                            style: textTheme.headlineSmall,
                          ),
                          Text(
                            'How are you feeling today?',
                            style: textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      backgroundImage: user?.avatarUrl != null
                          ? NetworkImage(user!.avatarUrl!)
                          : null,
                      child: user?.avatarUrl == null
                          ? const Icon(
                              PhosphorIconsFill.user,
                              color: AppColors.onSurfaceVariant,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _QuoteOfTheDayCard(
                  mascotKey: _mascotKey,
                  moodLabel: moodLabel,
                  moodState: _mascotMoodFor(moodLabel),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How are you feeling right now?',
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: Row(
                          children: [
                            for (final m in _moods)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _MoodButton(
                                  emoji: m.$1,
                                  label: m.$2,
                                  onTap: () {
                                    mood.logMood(m.$1, m.$2);
                                    HomeWidgetService.pushLatestMood(m.$2);
                                    _mascotKey.currentState
                                        ?.playSuccessAnimation();
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Take 1 minute to check in',
                              style: textTheme.labelMedium,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(
                              PhosphorIconsBold.arrowRight,
                              size: 16,
                            ),
                            label: const Text('Check-in!'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.surfaceTint,
                            backgroundImage: AssetImage('assets/pfp.png'),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Kai', style: textTheme.headlineSmall),
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 3,
                                    backgroundColor: Colors.green,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Online - ready to help',
                                    style: textTheme.labelMedium?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.clayLavender,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: clayShadows(0.5),
                        ),
                        child: Text(
                          '"Hi! I\'m here to listen and support you. Is '
                          'there something on your mind today?"',
                          style: textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/chat/session-kai-main'),
                          icon: const Icon(PhosphorIconsFill.chatCircle),
                          label: const Text('Start Chatting'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: PhosphorIconsFill.fire,
                        value: '${mood.streakDays}',
                        label: 'Days Streak',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: PhosphorIconsFill.checkCircle,
                        value: '${mood.tasksDone}',
                        label: 'Tasks Done',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: PhosphorIconsFill.heart,
                        value: '${mood.moodScorePercent}%',
                        label: 'Mood Score',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Conversations',
                      style: textTheme.headlineSmall,
                    ),
                    TextButton(onPressed: () {}, child: const Text('View All')),
                  ],
                ),
                const SizedBox(height: 8),
                FutureBuilder(
                  future: context.read<ChatRepository>().getSessions(),
                  builder: (context, snapshot) {
                    final sessions = snapshot.data ?? const [];
                    return Column(
                      children: [
                        for (final s in sessions)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ConversationTile(session: s),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // This screen is nested inside AppShell's own Scaffold, so a default-
      // positioned FAB lands at the absolute screen bottom — underneath
      // AppShell's persistent bottom nav bar. Push it up to clear that bar.
      floatingActionButton: const Padding(
        padding: EdgeInsets.only(bottom: 96),
        child: DashboardFab(),
      ),
    );
  }
}

class _QuoteOfTheDayCard extends StatelessWidget {
  const _QuoteOfTheDayCard({
    this.mascotKey,
    this.moodLabel,
    this.moodState = MascotMood.neutral,
  });

  final GlobalKey<InteractiveMascotState>? mascotKey;
  final String? moodLabel;
  final MascotMood moodState;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final quote = MentalHealthQuotes.quoteOfTheDay();
    return GlassCard(
      borderColor: AppColors.primaryContainer.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                PhosphorIconsFill.quotes,
                color: AppColors.primaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Quote of the day',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // The capybara "says" the quote itself: a large bubble holding
          // the actual quote text, tail pointing right into a fixed mascot
          // beside it — one reading interaction instead of a static quote
          // block plus an unrelated random bubble underneath it.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SpeechBubble(
                  text: quote.text,
                  tailSide: BubbleTailSide.right,
                  maxWidth: double.infinity,
                  fontSize: 14,
                  premium: true,
                ),
              ),
              const SizedBox(width: 12),
              InteractiveMascot(
                key: mascotKey,
                size: 88,
                moodLabel: moodLabel,
                moodState: moodState,
                enableSpeechBubble: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Clay(
          borderRadius: 20,
          depth: 0.6,
          color: AppColors.clayLavender,
          padding: const EdgeInsets.all(12),
          child: AppleEmoji(emoji, size: 32),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      borderRadius: 20,
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryContainer),
          const SizedBox(height: 4),
          Text(value, style: textTheme.headlineSmall),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: textTheme.labelMedium?.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.session});

  final ChatSession session;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isAi = session.type == ChatSessionType.ai;
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: () => context.go('/chat/${session.id}'),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryContainer.withValues(
                alpha: 0.15,
              ),
              backgroundImage: isAi ? const AssetImage('assets/pfp.png') : null,
              child: isAi
                  ? null
                  : const Icon(
                      PhosphorIconsFill.user,
                      color: AppColors.primaryContainer,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    session.lastMessagePreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isAi ? 'AI' : 'Counselor',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
