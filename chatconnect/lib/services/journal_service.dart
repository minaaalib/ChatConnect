import 'package:flutter/foundation.dart';

import '../models/journal_entry.dart';

class JournalService extends ChangeNotifier {
  JournalService()
    : _entries = [
        JournalEntry(
          id: 'journal-seed-1',
          userId: 'mock-user-1',
          title: 'Exam week reflections',
          content:
              "Today was overwhelming but I used the 4-7-8 breathing "
              "exercise Kai suggested before my exam. It actually helped "
              "me calm down.",
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          moodEmoji: '😔',
        ),
        JournalEntry(
          id: 'journal-seed-2',
          userId: 'mock-user-1',
          title: 'Grateful moments',
          content:
              'Had lunch with my roommates and it reminded me I have '
              'people around me who care. Feeling a little lighter.',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          moodEmoji: '😊',
        ),
      ];

  final List<JournalEntry> _entries;

  List<JournalEntry> get entries => List.unmodifiable(_entries);

  void addEntry({
    required String title,
    required String content,
    String? moodEmoji,
  }) {
    _entries.insert(
      0,
      JournalEntry(
        id: 'journal-${DateTime.now().microsecondsSinceEpoch}',
        userId: 'mock-user-1',
        title: title,
        content: content,
        createdAt: DateTime.now(),
        moodEmoji: moodEmoji,
      ),
    );
    notifyListeners();
  }

  void deleteEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
