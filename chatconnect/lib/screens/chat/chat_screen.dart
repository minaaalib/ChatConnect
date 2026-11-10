import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/chat_message.dart';
import '../../models/chat_session.dart';
import '../../models/crisis_alert.dart';
import '../../services/crisis_alert_reporter.dart';
import '../../services/chat_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/clay.dart';
import '../../widgets/gradient_background.dart';
import '../dashboard/dashboard_screen.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/crisis_alert_card.dart';
import 'widgets/sos_overlay.dart';
import 'widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <ChatMessage>[];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _kaiTyping = false;
  bool _loading = true;
  ChatSession? _session;

  late final ChatRepository _repo;

  static const _quickReplies = [
    'I feel anxious',
    "Can't sleep",
    'Family issues',
    'Academic stress',
  ];

  @override
  void initState() {
    super.initState();
    _repo = context.read<ChatRepository>();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final sessions = await _repo.getSessions();
    final history = await _repo.getMessages(widget.sessionId);
    if (!mounted) return;
    setState(() {
      for (final s in sessions) {
        if (s.id == widget.sessionId) {
          _session = s;
          break;
        }
      }
      _messages.addAll(history);
      _loading = false;
    });
    _scrollToBottom();
  }

  bool get _isCounselorSession => _session?.type == ChatSessionType.counselor;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    setState(() {
      _messages.add(
        ChatMessage(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          sessionId: widget.sessionId,
          sender: MessageSender.user,
          text: text,
          createdAt: DateTime.now(),
        ),
      );
      _kaiTyping = true;
    });
    _scrollToBottom();

    final reply = await _repo.sendMessage(
      sessionId: widget.sessionId,
      text: text,
    );

    if (!mounted) return;
    setState(() {
      _kaiTyping = false;
      _messages.add(reply);
    });
    _scrollToBottom();

    // Let the Guidance Office know (only when Supabase is configured).
    if (reply.sosTriggered || reply.isCrisisAlert) {
      context.read<CrisisAlertReporter?>()?.report(
        source: reply.sosTriggered ? CrisisSource.keyword : CrisisSource.ai,
        studentMessage: text,
      );
    }

    if (reply.sosTriggered) {
      SosOverlay.show(
        context,
        onConnectCounselor: () {
          if (!_isCounselorSession) {
            context.go('/chat/session-counselor-1');
          }
        },
      );
    } else if (reply.action != 'NONE') {
      _handleAction(reply.action);
    }
  }

  /// Hands off to an app feature Kai decided the student explicitly asked
  /// for (see kai-backend's KaiAction). Skipped entirely when sosTriggered —
  /// the SOS overlay takes priority over any feature hand-off.
  void _handleAction(String action) {
    switch (action) {
      case 'START_BREATHING':
        context.go('/dashboard');
        // Give the dashboard a frame to build before driving its mascot key.
        Future.delayed(
          const Duration(milliseconds: 300),
          DashboardScreen.triggerBreathingExercise,
        );
      case 'OPEN_JOURNAL':
        context.go('/journal');
      case 'BOOK_APPOINTMENT':
        context.go('/appointment');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _ChatHeader(
                session: _session,
                onBack: () => context.go('/chat'),
                onSos: () => SosOverlay.show(
                  context,
                  onConnectCounselor: () {
                    if (!_isCounselorSession) {
                      context.go('/chat/session-counselor-1');
                    }
                  },
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _messages.length + (_kaiTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _messages.length) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TypingIndicator(
                                isCounselor: _isCounselorSession,
                              ),
                            );
                          }
                          final message = _messages[index];
                          // Only the most recent message's suggestions stay
                          // tappable — older ones would just clutter the
                          // scroll once the conversation has moved on.
                          final isLatest =
                              index == _messages.length - 1 && !_kaiTyping;
                          if (message.isCrisisAlert) {
                            // Show Kai's actual reply *and* the alert card —
                            // flagging a crisis shouldn't erase what Kai said.
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ChatBubble(
                                    message: message,
                                    onQuickReply: _send,
                                    showQuickReplies: isLatest,
                                  ),
                                  const SizedBox(height: 8),
                                  CrisisAlertCard(
                                    onConnect: () {
                                      if (!_isCounselorSession) {
                                        context.go('/chat/session-counselor-1');
                                      }
                                    },
                                    onContinue: () {},
                                  ),
                                ],
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ChatBubble(
                              message: message,
                              onQuickReply: _send,
                              showQuickReplies: isLatest,
                            ),
                          );
                        },
                      ),
              ),
              _ChatInputBar(
                controller: _textController,
                quickReplies: _quickReplies,
                onSend: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.session,
    required this.onBack,
    required this.onSos,
  });

  final ChatSession? session;
  final VoidCallback onBack;
  final VoidCallback onSos;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isCounselor = session?.type == ChatSessionType.counselor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.claySurface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: clayShadows(0.5),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              PhosphorIconsFill.arrowLeft,
              color: AppColors.primary,
            ),
          ),
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryContainer.withValues(alpha: 0.45),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryContainer,
                  backgroundImage: isCounselor
                      ? null
                      : const AssetImage('assets/pfp.png'),
                  child: isCounselor
                      ? const Icon(
                          PhosphorIconsFill.user,
                          color: AppColors.onPrimaryContainer,
                        )
                      : null,
                ),
              ),
              if (!isCounselor)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCounselor ? (session?.title ?? 'Counselor') : 'Kai',
                  style: textTheme.headlineSmall,
                ),
                Text(
                  isCounselor
                      ? 'Usually responds within a few hours'
                      : 'ONLINE · 24/7',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCounselor
                  ? AppColors.verifiedContainer
                  : AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: (isCounselor ? AppColors.verified : AppColors.primary)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCounselor
                      ? PhosphorIconsFill.sealCheck
                      : PhosphorIconsFill.robot,
                  size: 12,
                  color: isCounselor ? AppColors.verified : AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  isCounselor ? 'Human Counselor' : 'AI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isCounselor ? AppColors.verified : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onSos,
            tooltip: 'Emergency SOS',
            icon: const Icon(
              PhosphorIconsFill.firstAidKit,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.quickReplies,
    required this.onSend,
  });

  final TextEditingController controller;
  final List<String> quickReplies;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.claySurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: clayShadows(0.5),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: quickReplies.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return ActionChip(
                  label: Text(
                    quickReplies[i],
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: AppColors.surfaceTint,
                  shape: const StadiumBorder(
                    side: BorderSide(color: AppColors.borderSubtle),
                  ),
                  onPressed: () => onSend(quickReplies[i]),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                  ),
                  onSubmitted: onSend,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: IconButton(
                  icon: const Icon(
                    PhosphorIconsFill.paperPlaneRight,
                    color: AppColors.onPrimary,
                  ),
                  onPressed: () => onSend(controller.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
