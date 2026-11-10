import 'dart:math';

import '../models/chat_message.dart';
import '../models/chat_session.dart';
import 'chat_repository.dart';

class MockChatRepository implements ChatRepository {
  final Map<String, List<ChatMessage>> _messagesBySession = {
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
      ChatMessage(
        id: 'c2',
        sessionId: 'session-counselor-1',
        sender: MessageSender.counselor,
        text: "Let's continue our session next Tuesday. You're doing great.",
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
    'session-sleep': [
      ChatMessage(
        id: 's1',
        sessionId: 'session-sleep',
        sender: MessageSender.user,
        text: "I've been struggling to fall asleep before 2 AM...",
        createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
      ),
      ChatMessage(
        id: 's2',
        sessionId: 'session-sleep',
        sender: MessageSender.kai,
        text:
            'That kind of late-night wired feeling is exhausting on its '
            'own. Want to try a wind-down routine together, or talk '
            "through what's keeping your mind busy first?",
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        quickReplies: const ['Wind-down routine', "What's on my mind"],
      ),
    ],
  };

  final List<ChatSession> _sessions = [
    ChatSession(
      id: 'session-kai-main',
      userId: 'mock-user-1',
      title: 'Kai · AI Assistant',
      lastMessagePreview:
          "I understand how you feel. It's okay to have "
          'these moments...',
      updatedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      type: ChatSessionType.ai,
    ),
    ChatSession(
      id: 'session-counselor-1',
      userId: 'mock-user-1',
      title: 'Ms. Aurine',
      lastMessagePreview:
          "Let's continue our session next Tuesday. You're doing great.",
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      type: ChatSessionType.counselor,
    ),
    ChatSession(
      id: 'session-sleep',
      userId: 'mock-user-1',
      title: 'Improving Sleep Quality',
      lastMessagePreview: "I've been struggling to fall asleep before 2 AM...",
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      type: ChatSessionType.ai,
    ),
  ];

  // Heuristic substring list, not real language understanding — it will
  // still miss phrasings not covered here. Grouped by theme to make gaps
  // easier to spot when extending this list.
  static const _crisisKeywords = [
    // Suicidal ideation
    'suicide',
    'suicidal',
    'commit suicide',
    'kill myself',
    'killing myself',
    'end my life',
    'ending my life',
    'take my own life',
    'taking my own life',
    'want to die',
    'wanna die',
    'want to be dead',
    'wish i was dead',
    'wish i were dead',
    'better off dead',
    'rather be dead',
    // Hopelessness framed as wanting to disappear/not exist
    'hopeless',
    "don't want to live",
    'do not want to live',
    'no reason to live',
    'no point in living',
    'no point living',
    'not worth living',
    "nothing left to live for",
    'nothing matters anymore',
    'better off without me',
    "don't want to be here anymore",
    "don't want to exist",
    'disappear forever',
    'give up on life',
    "can't go on",
    'cant go on',
    'end it all',
    // Self-harm
    'self harm',
    'self-harm',
    'hurt myself',
    'hurting myself',
    'cut myself',
    'cutting myself',
  ];

  static const _adviceTriggers = [
    'give me advice',
    'give me some advice',
    'any advice',
    'got any advice',
    'need advice',
    'need some advice',
    'want advice',
    'want some advice',
    'advice please',
    'what should i do',
    'what do i do',
    'do you have any advice',
  ];

  // Topic keywords checked against the user's own earlier messages in this
  // session, so "give me advice" picks up something relevant to what they
  // already said rather than a generic tip. Content paraphrased from the
  // mental-health fact bank in datasets/1.zip (intents.json).
  static const _topicKeywords = {
    'anxiety': ['anxious', 'anxiety', 'panic', 'nervous', 'worry', 'worried'],
    'sleep': [
      'sleep',
      'insomnia',
      "can't sleep",
      'cant sleep',
      'trouble sleeping',
      'awake at night',
    ],
    'stress': ['stress', 'stressed', 'exam', 'exams', 'academic', 'deadline'],
    'relationships': [
      'family',
      'relationship',
      'friend',
      'friends',
      'parents',
      'mom',
      'dad',
    ],
    'low_mood': ['sad', 'down', 'lonely', 'alone', 'empty', 'worthless'],
  };

  static const _topicAdvice = {
    'anxiety': [
      'One thing that helps with anxiety in the moment is slow breathing — '
          'in through your nose for 4 counts, hold for 4, out for 6. It '
          "won't fix the cause, but it can take the edge off.",
      "Anxiety often comes from worrying about something that hasn't "
          'happened yet. Naming the specific thing you\'re worried about — '
          'out loud or written down — can make it feel more manageable than '
          'the vague dread.',
    ],
    'sleep': [
      'Good sleep makes a real difference for mental health. A simple '
          'wind-down routine — dim lights, no screens, same bedtime — can '
          "help your body learn when it's time to rest.",
      "If your mind is racing at night, try writing down what's on it "
          'before bed. Getting it out of your head and onto paper sometimes '
          'makes it easier to let go of for the night.',
    ],
    'stress': [
      'When everything feels like a lot, it helps to give yourself '
          'permission to take a break first — overthinking a problem on its '
          'own rarely solves it.',
      'Breaking a big stressful task into smaller steps can make it feel '
          'less overwhelming. Pick just the next step, not the whole thing.',
    ],
    'relationships': [
      'Family and relationship stuff is heavy precisely because it matters '
          "so much. It can help to separate what's in your control — how "
          "you respond — from what isn't, like how the other person acts.",
      'If things feel tense at home, having even one person outside the '
          'situation to talk to — a friend, counselor, or trusted adult — '
          'can help you get some perspective.',
    ],
    'low_mood': [
      'Talking to someone you trust — a friend, family member, or '
          'counselor — really does help, even just to vent. Isolating '
          'tends to make heavy feelings heavier, not lighter.',
      'Moving your body, even a short walk, and staying connected to '
          'people who care about you both reliably help mood over time — '
          "even when they're the last thing you feel like doing.",
    ],
    'general': [
      'A few things that reliably help with mental wellbeing: talking to '
          'someone, getting enough sleep, moving your body, and staying '
          'connected to people who care about you. Is there one of those '
          'that feels hardest for you right now?',
      'It depends a bit on what\'s going on for you — want to tell me more '
          'about what\'s been on your mind, so I can give advice that '
          'actually fits your situation?',
    ],
  };

  static const _empathyReplies = [
    'I understand anxiety can be overwhelming. Would you like to try a '
        'breathing exercise together?',
    "Thank you for sharing that with me. That sounds really hard, and it "
        "makes sense you'd feel that way.",
    "I'm here with you. Would it help to break this down together, one "
        'step at a time?',
    "That's a lot to carry. What usually helps you feel even a little bit "
        'better?',
  ];

  /// Unlike Kai's replies, these stand in for an actual human counselor
  /// reading the message later — no instant "empathy reply" voice, since a
  /// real counselor isn't watching the chat live the way Kai is.
  static const _counselorAckReplies = [
    "Thanks for sharing this — I've made a note of it and we can pick it "
        'up in our next session.',
    "I've read this. Let's talk through it properly when we meet — "
        'in the meantime, take care of yourself.',
    "Got it, thank you for telling me. I'll follow up on this soon.",
  ];

  final _random = Random();

  /// Scans the user's own prior messages (most recent first) for a known
  /// topic, so a bare "give me advice" picks up what they already said
  /// instead of needing the topic restated. Falls back to 'general'.
  String _detectTopic(List<ChatMessage> history) {
    for (var i = history.length - 1; i >= 0; i--) {
      final message = history[i];
      if (message.sender != MessageSender.user) continue;
      final lower = message.text.toLowerCase();
      for (final entry in _topicKeywords.entries) {
        if (entry.value.any((k) => lower.contains(k))) {
          return entry.key;
        }
      }
    }
    return 'general';
  }

  @override
  Future<List<ChatSession>> getSessions() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_sessions);
  }

  @override
  Future<List<ChatMessage>> getMessages(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_messagesBySession[sessionId] ?? const []);
  }

  /// Returns Kai's reply for an AI session, or a stand-in acknowledgment for
  /// a counselor session (a real counselor isn't watching the chat live the
  /// way Kai is). Crisis-keyword detection applies to every session
  /// regardless of who the student is nominally talking to.
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

    await Future.delayed(const Duration(milliseconds: 900));

    final isCrisis = _crisisKeywords.any((k) => text.toLowerCase().contains(k));

    ChatSession? session;
    for (final s in _sessions) {
      if (s.id == sessionId) {
        session = s;
        break;
      }
    }
    final isCounselorSession = session?.type == ChatSessionType.counselor;

    final ChatMessage reply;
    if (isCrisis) {
      reply = ChatMessage(
        id: 'k-${DateTime.now().microsecondsSinceEpoch}',
        sessionId: sessionId,
        sender: MessageSender.kai,
        text:
            "I'm here for you. It sounds like you're going through a lot "
            'right now. Would you like to talk to a human counselor?',
        createdAt: DateTime.now(),
        isCrisisAlert: true,
      );
    } else if (isCounselorSession) {
      reply = ChatMessage(
        id: 'c-${DateTime.now().microsecondsSinceEpoch}',
        sessionId: sessionId,
        sender: MessageSender.counselor,
        text:
            _counselorAckReplies[_random.nextInt(_counselorAckReplies.length)],
        createdAt: DateTime.now(),
      );
    } else if (_adviceTriggers.any((k) => text.toLowerCase().contains(k))) {
      final topic = _detectTopic(history);
      final options = _topicAdvice[topic] ?? _topicAdvice['general']!;
      reply = ChatMessage(
        id: 'k-${DateTime.now().microsecondsSinceEpoch}',
        sessionId: sessionId,
        sender: MessageSender.kai,
        text: options[_random.nextInt(options.length)],
        createdAt: DateTime.now(),
        quickReplies: const ['Thanks, that helps', 'Tell me more'],
      );
    } else {
      reply = ChatMessage(
        id: 'k-${DateTime.now().microsecondsSinceEpoch}',
        sessionId: sessionId,
        sender: MessageSender.kai,
        text: _empathyReplies[_random.nextInt(_empathyReplies.length)],
        createdAt: DateTime.now(),
        quickReplies: const [
          "Yes, let's try",
          'Tell me more',
          'Help me calm down',
        ],
      );
    }
    history.add(reply);
    return reply;
  }
}

// Later, once a Supabase project + `kai-chat` Edge Function exist, swap
// MockChatRepository for something like:
//
// class SupabaseEdgeFunctionChatRepository implements ChatRepository {
//   final _client = Supabase.instance.client;
//
//   @override
//   Future<ChatMessage> sendMessage({
//     required String sessionId,
//     required String text,
//   }) async {
//     // The Claude API key lives only in the Edge Function's server-side
//     // environment — never bundle it into the Flutter app, where it could
//     // be extracted from the compiled binary.
//     final res = await _client.functions.invoke(
//       'kai-chat',
//       body: {'sessionId': sessionId, 'text': text},
//     );
//     return ChatMessage.fromJson(res.data);
//   }
//   // ...getSessions()/getMessages() would read from Supabase tables.
// }
