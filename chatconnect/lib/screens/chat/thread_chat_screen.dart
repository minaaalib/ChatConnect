import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/counselor_thread.dart';
import '../../services/counselor_chat_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/clay.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/readable_width.dart';

/// Live chat between a student and the Guidance Office, used on both sides.
/// Pass [threadId] when it's known (counselor opening a thread), or
/// [studentId] to find/create that student's thread.
class ThreadChatScreen extends StatefulWidget {
  const ThreadChatScreen({
    super.key,
    this.threadId,
    this.studentId,
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.viewerIsCounselor = false,
    this.headerAction,
  }) : assert(threadId != null || studentId != null);

  final String? threadId;
  final String? studentId;
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final bool viewerIsCounselor;
  final Widget? headerAction;

  @override
  State<ThreadChatScreen> createState() => _ThreadChatScreenState();
}

class _ThreadChatScreenState extends State<ThreadChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  late final CounselorChatRepository _repo;
  String? _threadId;
  Stream<List<ThreadMessage>>? _stream;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _repo = context.read<CounselorChatRepository>();
    _open();
  }

  Future<void> _open() async {
    try {
      final id =
          widget.threadId ?? await _repo.threadIdForStudent(widget.studentId!);
      if (!mounted) return;
      setState(() {
        _threadId = id;
        _stream = _repo.messages(id);
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = "Couldn't open this chat. Check your connection.",
      );
    }
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    final threadId = _threadId;
    if (body.isEmpty || threadId == null || _sending) return;
    setState(() => _sending = true);
    try {
      await _repo.send(threadId: threadId, body: body);
      _text.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message not sent. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = _repo.currentUserId;
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: ReadableWidth(
            child: Column(
              children: [
                _Header(
                  title: widget.title,
                  subtitle: widget.subtitle,
                  onBack: widget.onBack,
                  viewerIsCounselor: widget.viewerIsCounselor,
                  action: widget.headerAction,
                ),
                Expanded(
                  child: _error != null
                      ? _Centered(
                          text: _error!,
                          action: TextButton(
                            onPressed: _open,
                            child: const Text('Try again'),
                          ),
                        )
                      : _stream == null
                      ? const Center(child: CircularProgressIndicator())
                      : StreamBuilder<List<ThreadMessage>>(
                          stream: _stream,
                          builder: (context, snap) {
                            if (snap.hasError) {
                              return _Centered(
                                text: 'Connection lost.',
                                action: TextButton(
                                  onPressed: _open,
                                  child: const Text('Reconnect'),
                                ),
                              );
                            }
                            if (!snap.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final messages = snap.data!;
                            if (messages.isEmpty) {
                              return _Centered(
                                text: widget.viewerIsCounselor
                                    ? 'No messages yet. Say hello to start '
                                          'the conversation.'
                                    : 'Send a message to the Guidance Office. '
                                          'A counselor will reply here.\n\n'
                                          'If you are in danger right now, use '
                                          'the SOS button instead.',
                              );
                            }
                            _scrollToBottom();
                            return ListView.builder(
                              controller: _scroll,
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              itemCount: messages.length,
                              itemBuilder: (context, i) => _Bubble(
                                message: messages[i],
                                mine: messages[i].senderId == me,
                              ),
                            );
                          },
                        ),
                ),
                _InputBar(
                  controller: _text,
                  sending: _sending,
                  enabled: _threadId != null,
                  onSend: _send,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.viewerIsCounselor,
    this.action,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final bool viewerIsCounselor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
            icon: const Icon(PhosphorIconsBold.arrowLeft),
            color: AppColors.primary,
          ),
          Clay(
            shape: BoxShape.circle,
            depth: 0.5,
            color: viewerIsCounselor
                ? AppColors.clayLavender
                : AppColors.verifiedContainer,
            padding: const EdgeInsets.all(10),
            child: Icon(
              viewerIsCounselor
                  ? PhosphorIconsFill.student
                  : PhosphorIconsFill.sealCheck,
              color: viewerIsCounselor ? AppColors.primary : AppColors.verified,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: textTheme.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final ThreadMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('MMM d · h:mm a').format(message.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width.clamp(0, 800) * 0.75,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: mine
                    ? AppColors.primaryContainer
                    : AppColors.claySurface,
                boxShadow: clayShadows(0.4),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(mine ? 22 : 6),
                  bottomRight: Radius.circular(mine ? 6 : 22),
                ),
              ),
              child: Text(
                message.body,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: mine ? Colors.white : AppColors.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(fontSize: 11, color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.claySurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: clayShadows(0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              maxLength: 4000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Type a message…',
                counterText: '',
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: enabled && !sending ? onSend : null,
            child: Clay(
              shape: BoxShape.circle,
              depth: 0.6,
              color: AppColors.primaryContainer,
              padding: const EdgeInsets.all(14),
              child: sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      PhosphorIconsFill.paperPlaneRight,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
