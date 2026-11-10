/// One student's chat thread with the Guidance Office.
class CounselorThread {
  const CounselorThread({
    required this.id,
    required this.studentId,
    required this.lastMessageAt,
    this.lastMessagePreview,
    this.lastSenderId,
  });

  final String id;
  final String studentId;
  final DateTime lastMessageAt;
  final String? lastMessagePreview;
  final String? lastSenderId;

  /// True when the student sent the latest message (a counselor owes a reply).
  bool get awaitingCounselor =>
      lastSenderId != null && lastSenderId == studentId;

  factory CounselorThread.fromRow(Map<String, dynamic> row) {
    return CounselorThread(
      id: row['id'] as String,
      studentId: row['student_id'] as String,
      lastMessageAt: DateTime.parse(row['last_message_at'] as String).toLocal(),
      lastMessagePreview: row['last_message_preview'] as String?,
      lastSenderId: row['last_sender_id'] as String?,
    );
  }
}

class ThreadMessage {
  const ThreadMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String threadId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  factory ThreadMessage.fromRow(Map<String, dynamic> row) {
    return ThreadMessage(
      id: row['id'] as String,
      threadId: row['thread_id'] as String,
      senderId: row['sender_id'] as String,
      body: row['body'] as String,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }
}
