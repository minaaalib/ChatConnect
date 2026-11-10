enum ChatSessionType { ai, counselor }

class ChatSession {
  const ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.lastMessagePreview,
    required this.updatedAt,
    required this.type,
  });

  final String id;
  final String userId;
  final String title;
  final String lastMessagePreview;
  final DateTime updatedAt;
  final ChatSessionType type;
}
