import 'package:flutter/foundation.dart';

import '../models/mood_entry.dart';

class MoodService extends ChangeNotifier {
  final List<MoodEntry> _entries = [];

  int streakDays = 7;
  int tasksDone = 3;
  int moodScorePercent = 92;

  List<MoodEntry> get entries => List.unmodifiable(_entries);

  void logMood(String emoji, String label) {
    _entries.insert(
      0,
      MoodEntry(
        id: 'mood-${DateTime.now().microsecondsSinceEpoch}',
        userId: 'mock-user-1',
        moodEmoji: emoji,
        moodLabel: label,
        createdAt: DateTime.now(),
      ),
    );
    tasksDone += 1;
    notifyListeners();
  }
}
