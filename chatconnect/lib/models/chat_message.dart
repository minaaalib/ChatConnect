enum MessageSender { user, kai, counselor, system }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.sender,
    required this.text,
    required this.createdAt,
    this.quickReplies = const [],
    this.isCrisisAlert = false,
    this.sosTriggered = false,
    this.action = 'NONE',
  });

  final String id;
  final String sessionId;
  final MessageSender sender;
  final String text;
  final DateTime createdAt;
  final List<String> quickReplies;

  /// Soft signal (LLM judgment or local keyword match): shows the inline
  /// [CrisisAlertCard] offering to connect to a counselor.
  final bool isCrisisAlert;

  /// Hard signal from the backend's hardcoded keyword filter — never from
  /// the LLM alone. Shows the blocking [SosOverlay] with emergency contacts.
  final bool sosTriggered;

  /// One of "NONE", "START_BREATHING", "OPEN_JOURNAL", "BOOK_APPOINTMENT" —
  /// set by kai-backend only when the student explicitly asked for that app
  /// feature. The chat screen navigates there after showing this message.
  final String action;
}
