import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/insights_models.dart';

class InsightsService extends ChangeNotifier {
  final List<MoodPoint> weeklyMoodTrend = const [
    MoodPoint(label: 'Mon', value: 5.5),
    MoodPoint(label: 'Tue', value: 6.0),
    MoodPoint(label: 'Wed', value: 7.2),
    MoodPoint(label: 'Thu', value: 6.8),
    MoodPoint(label: 'Fri', value: 6.2),
    MoodPoint(label: 'Sat', value: 7.8),
    MoodPoint(label: 'Sun', value: 8.4),
  ];

  final WeeklySummary weeklySummary = const WeeklySummary(
    averageMood: 7.2,
    moodDelta: 0.8,
    totalChats: 5,
    aiChats: 3,
    counselorChats: 2,
    copingScorePercent: 85,
  );

  final List<WordCloudWord> wordCloud = const [
    WordCloudWord(text: 'Grateful', weight: 24),
    WordCloudWord(text: 'Routine', weight: 14),
    WordCloudWord(text: 'Overwhelmed', weight: 28),
    WordCloudWord(text: 'Peaceful', weight: 18),
    WordCloudWord(text: 'Study', weight: 12),
    WordCloudWord(text: 'Pressure', weight: 20),
    WordCloudWord(text: 'Focused', weight: 16),
    WordCloudWord(text: 'Morning', weight: 14),
  ];

  final List<Achievement> achievements = const [
    Achievement(
      title: '10 Day Streak',
      icon: PhosphorIconsFill.star,
      unlocked: true,
    ),
    Achievement(
      title: '5 Supportive Chats',
      icon: PhosphorIconsFill.heart,
      unlocked: false,
    ),
    Achievement(
      title: 'First Month',
      icon: PhosphorIconsFill.target,
      unlocked: true,
    ),
    Achievement(
      title: 'Growth Mindset',
      icon: PhosphorIconsFill.trendUp,
      unlocked: true,
    ),
  ];

  final String kaiInsight =
      "Based on your conversations, we've noticed you're feeling more "
      'anxious during exam weeks. Here are some tailored coping strategies '
      'to help you navigate this period.';
}
