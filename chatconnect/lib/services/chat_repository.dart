import '../models/chat_message.dart';
import '../models/chat_session.dart';

abstract class ChatRepository {
  Future<List<ChatSession>> getSessions();

  Future<List<ChatMessage>> getMessages(String sessionId);

  /// Sends [text] as a user message in [sessionId] and returns the reply —
  /// from Kai for an AI session, or a counselor for a counselor session.
  Future<ChatMessage> sendMessage({
    required String sessionId,
    required String text,
  });
}
