import 'dart:convert';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/chat_message.dart';
import '../models/chat_session.dart';
import 'chat_repository.dart';

/// Talks to kai-backend's `/kai-chat` endpoint (FastAPI, fronting Google
/// Gemini) for AI sessions, so crisis judgment comes from a real model
/// reading the message rather than substring matching alone. The backend
/// also runs its own hardcoded keyword filter ahead of the model and reports
/// that separately as `crisis_detected` — see [ChatMessage.sosTriggered].
///
/// Counselor sessions stay a local stand-in — there's no real counselor
/// integration yet, and a real counselor isn't watching the chat live the
/// way Kai is.
class LiveChatRepository implements ChatRepository {
  LiveChatRepository({this.includeOfflineCounselor = true});

  /// False when Supabase is on: the real Guidance Office chat replaces the
  /// canned "Ms. Aurine" stand-in in the recent-conversations list.
  final bool includeOfflineCounselor;

  final _messagesBySession = <String, List<ChatMessage>>{
    'session-kai-main': [
      ChatMessage(
        id: 'm1',
        sessionId: 'session-kai-main',
        sender: MessageSender.kai,
        text:
            "Hi! I'm Kai, your ChatConnect AI companion. I'm here to listen "
            'and support you. How are you feeling today?',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        quickReplies: const [
          "I'm feeling anxious",
          'I need someone to talk to',
          "I'm okay",
        ],
      ),
    ],
    'session-counselor-1': [
      ChatMessage(
        id: 'c1',
        sessionId: 'session-counselor-1',
        sender: MessageSender.counselor,
        text:
            "Hi, it's Ms. Aurine. Good to see you back — how has the week "
            'been since we last talked?',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ),
    ],
  };

  final _sessions = <ChatSession>[
    ChatSession(
      id: 'session-kai-main',
      userId: 'mock-user-1',
      title: 'Kai · AI Assistant',
      lastMessagePreview: "Hi! I'm Kai, your ChatConnect AI companion...",
      updatedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      type: ChatSessionType.ai,
    ),
    ChatSession(
      id: 'session-counselor-1',
      userId: 'mock-user-1',
      title: 'Ms. Aurine',
      lastMessagePreview:
          "Hi, it's Ms. Aurine. Good to see you back — how has the week "
          'been since we last talked?',
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      type: ChatSessionType.counselor,
    ),
  ];

  static const _counselorAckReplies = [
    "Thanks for sharing this — I've made a note of it and we can pick it "
        'up in our next session.',
    "I've read this. Let's talk through it properly when we meet — "
        'in the meantime, take care of yourself.',
    "Got it, thank you for telling me. I'll follow up on this soon.",
  ];

  final _random = Random();

  /// 10.0.2.2 is the Android emulator's route to the host machine's
  /// localhost. Override via KAI_BACKEND_URL in .env for web/desktop
  /// (http://127.0.0.1:8000) or a physical device on the same Wi-Fi
  /// (your machine's LAN IP) — see kai-backend/README.md.
  String get _baseUrl =>
      dotenv.env['KAI_BACKEND_URL'] ?? 'http://10.0.2.2:8000';

  @override
  Future<List<ChatSession>> getSessions() async {
    return List.unmodifiable(
      includeOfflineCounselor
          ? _sessions
          : _sessions.where((s) => s.type != ChatSessionType.counselor),
    );
  }

  @override
  Future<List<ChatMessage>> getMessages(String sessionId) async {
    return List.unmodifiable(_messagesBySession[sessionId] ?? const []);
  }

  @override
  Future<ChatMessage> sendMessage({
    required String sessionId,
    required String text,
  }) async {
    final history = _messagesBySession.putIfAbsent(sessionId, () => []);
    history.add(
      ChatMessage(
        id: 'u-${DateTime.now().microsecondsSinceEpoch}',
        sessionId: sessionId,
        sender: MessageSender.user,
        text: text,
        createdAt: DateTime.now(),
      ),
    );

    ChatSession? session;
    for (final s in _sessions) {
      if (s.id == sessionId) {
        session = s;
        break;
      }
    }

    final ChatMessage reply;
    if (session?.type == ChatSessionType.counselor) {
      reply = ChatMessage(
        id: 'c-${DateTime.now().microsecondsSinceEpoch}',
        sessionId: sessionId,
        sender: MessageSender.counselor,
        text:
            _counselorAckReplies[_random.nextInt(_counselorAckReplies.length)],
        createdAt: DateTime.now(),
      );
    } else {
      reply = await _askKai(sessionId: sessionId, history: history);
    }

    history.add(reply);
    return reply;
  }

  Future<ChatMessage> _askKai({
    required String sessionId,
    required List<ChatMessage> history,
  }) async {
    final priorTurns = history
        .take(
          history.length - 1,
        ) // exclude the message just added by sendMessage
        .where(
          (m) =>
              m.sender == MessageSender.user || m.sender == MessageSender.kai,
        )
        .map(
          (m) => {
            'role': m.sender == MessageSender.user ? 'user' : 'kai',
            'text': m.text,
          },
        )
        .toList();

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/kai-chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'session_id': sessionId,
              'message': history.last.text,
              'history': priorTurns,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return _unavailableReply(sessionId);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ChatMessage(
        id: 'k-${DateTime.now().microsecondsSinceEpoch}',
        sessionId: sessionId,
        sender: MessageSender.kai,
        text: data['reply'] as String,
        createdAt: DateTime.now(),
        isCrisisAlert: data['is_crisis'] as bool? ?? false,
        sosTriggered: data['crisis_detected'] as bool? ?? false,
        quickReplies: (data['quick_replies'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        action: data['action'] as String? ?? 'NONE',
      );
    } catch (_) {
      return _unavailableReply(sessionId);
    }
  }

  ChatMessage _unavailableReply(String sessionId) {
    return ChatMessage(
      id: 'k-${DateTime.now().microsecondsSinceEpoch}',
      sessionId: sessionId,
      sender: MessageSender.kai,
      text:
          "I'm having trouble connecting right now. If you need to talk to "
          "someone urgently, please reach out to Ms. Aurine, a trusted "
          'person, or campus security directly.',
      createdAt: DateTime.now(),
    );
  }
}
