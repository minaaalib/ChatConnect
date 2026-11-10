import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../services/insights_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/clay.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_chip.dart';
import '../../widgets/gradient_background.dart';
import 'widgets/mood_trend_chart.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int _rangeIndex = 0;
  static const _ranges = ['This Week', 'This Month', 'This Year'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final insights = context.watch<InsightsService>();
    final summary = insights.weeklySummary;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
            children: [
              Text(
                'Your Journey',
                style: textTheme.headlineLarge?.copyWith(fontSize: 28),
              ),
              Text(
                'Track your progress with AI insights',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _ranges.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => GlassChip(
                    label: _ranges[i],
                    selected: _rangeIndex == i,
                    onTap: () => setState(() => _rangeIndex = i),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GlassCard(
                borderColor: AppColors.primary.withValues(alpha: 0.2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          PhosphorIconsFill.brain,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Kai's Insight",
                          style: textTheme.headlineSmall?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(insights.kaiInsight, style: textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(PhosphorIconsFill.arrowRight),
                        label: const Text('View AI Recommendations'),
                      ),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              PhosphorIconsFill.trendUp,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text('Mood Trend', style: textTheme.headlineSmall),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'AI ANALYZED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    MoodTrendChart(points: insights.weeklyMoodTrend),
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
                        const Icon(
                          PhosphorIconsFill.calendarBlank,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'This Week at a Glance',
                          style: textTheme.headlineSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            label: 'Average Mood',
                            child: Row(
                              children: [
                                Text(
                                  summary.averageMood.toStringAsFixed(1),
                                  style: textTheme.headlineSmall?.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                                const Icon(
                                  PhosphorIconsFill.arrowUp,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                Text(
                                  summary.moodDelta.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatBox(
                            label: 'Total Chats',
                            child: Text(
                              '${summary.totalChats}',
                              style: textTheme.headlineSmall?.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Coping Score',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.outline,
                                ),
                              ),
                              Text(
                                '${summary.copingScorePercent}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: summary.copingScorePercent / 100,
                              minHeight: 8,
                              backgroundColor: AppColors.surfaceTint,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: AppColors.primaryContainer,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            PhosphorIconsFill.lightbulb,
                            color: AppColors.primaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Kai suggests focusing on sleep quality this weekend.',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                        const Icon(
                          PhosphorIconsFill.chatsCircle,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text('Your Words', style: textTheme.headlineSmall),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        for (final w in insights.wordCloud)
                          Text(
                            w.text,
                            style: TextStyle(
                              fontSize: w.weight,
                              fontWeight: w.weight > 20
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: AppColors.primary.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'PERSONALIZED FOR YOU',
                style: textTheme.labelMedium?.copyWith(letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              _RecommendationTile(
                icon: PhosphorIconsFill.wind,
                title: 'Breathing Exercise',
                subtitle: '5-minute session',
              ),
              const SizedBox(height: 12),
              _RecommendationTile(
                icon: PhosphorIconsFill.notePencil,
                title: 'Journal Prompts',
                subtitle: 'Unpack exam triggers',
              ),
              const SizedBox(height: 24),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          PhosphorIconsFill.trophy,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text('Achievements', style: textTheme.headlineSmall),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: insights.achievements.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 16),
                        itemBuilder: (context, i) {
                          final a = insights.achievements[i];
                          return Opacity(
                            opacity: a.unlocked ? 1 : 0.5,
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.clayLavender,
                                    shape: BoxShape.circle,
                                    boxShadow: clayShadows(0.5),
                                  ),
                                  child: Icon(a.icon, color: AppColors.primary),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 64,
                                  child: Text(
                                    a.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.outline),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(onPressed: () {}, child: const Text('Try Now')),
        ],
      ),
    );
  }
}
