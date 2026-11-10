import 'package:flutter/material.dart';

class MoodPoint {
  const MoodPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class WordCloudWord {
  const WordCloudWord({required this.text, required this.weight});

  final String text;
  final double weight;
}

class Achievement {
  const Achievement({
    required this.title,
    required this.icon,
    required this.unlocked,
  });

  final String title;
  final IconData icon;
  final bool unlocked;
}

class WeeklySummary {
  const WeeklySummary({
    required this.averageMood,
    required this.moodDelta,
    required this.totalChats,
    required this.aiChats,
    required this.counselorChats,
    required this.copingScorePercent,
  });

  final double averageMood;
  final double moodDelta;
  final int totalChats;
  final int aiChats;
  final int counselorChats;
  final int copingScorePercent;
}
