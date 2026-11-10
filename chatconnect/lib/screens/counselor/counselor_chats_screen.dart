import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../../services/counselor_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/clay.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import 'time_ago.dart';

/// All student chat threads, newest activity first.
class CounselorChatsScreen extends StatelessWidget {
  const CounselorChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final service = context.watch<CounselorService>();
    final threads = service.threads;
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text('Student chats', style: textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                service.threadsAwaitingReply > 0
                    ? '${service.threadsAwaitingReply} waiting for a reply'
                    : 'All caught up',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              if (threads.isEmpty)
                GlassCard(
                  child: Text(
                    'No conversations yet. Students appear here once they '
                    'message the Guidance Office, or when you message them '
                    'from an alert or appointment.',
                    style: textTheme.bodyMedium,
                  ),
                ),
              for (final t in threads)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: () => context.go(
                        '/counselor/chats/${t.id}?student=${t.studentId}',
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Clay(
                              shape: BoxShape.circle,
                              depth: 0.5,
                              color: AppColors.clayLavender,
                              padding: const EdgeInsets.all(12),
                              child: const Icon(
                                PhosphorIconsFill.student,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.studentName(t.studentId),
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    t.lastMessagePreview ?? 'No messages yet',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: t.awaitingCounselor
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  timeAgo(t.lastMessageAt),
                                  style: textTheme.labelMedium,
                                ),
                                const SizedBox(height: 6),
                                if (t.awaitingCounselor)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.tertiary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
