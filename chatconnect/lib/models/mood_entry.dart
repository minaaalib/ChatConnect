class MoodEntry {
  const MoodEntry({
    required this.id,
    required this.userId,
    required this.moodEmoji,
    required this.moodLabel,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String userId;
  final String moodEmoji;
  final String moodLabel;
  final DateTime createdAt;
  final String? note;
}
