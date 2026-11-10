import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/appointment.dart';
import '../../models/crisis_alert.dart';
import '../../services/auth_service.dart';
import '../../services/counselor_chat_repository.dart';
import '../../services/counselor_service.dart';
import '../../services/meet_scheduler.dart';
import '../../theme/app_colors.dart';
import '../../widgets/clay.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_chip.dart';
import '../../widgets/gradient_background.dart';
import 'time_ago.dart';

/// Counselor home: crisis alerts and appointment requests, live.
class CounselorInboxScreen extends StatefulWidget {
  const CounselorInboxScreen({super.key});

  @override
  State<CounselorInboxScreen> createState() => _CounselorInboxScreenState();
}

class _CounselorInboxScreenState extends State<CounselorInboxScreen> {
  bool _showAlerts = true;
  bool _showClosed = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final service = context.watch<CounselorService>();
    final me = context.watch<AuthService>().currentUser;

    final alerts = _showClosed
        ? service.alerts
        : service.alerts.where((a) => a.isOpen).toList();
    // Most urgent first: keyword (SOS) alerts, then newest.
    alerts.sort((a, b) {
      final rank = _alertRank(a).compareTo(_alertRank(b));
      return rank != 0 ? rank : b.createdAt.compareTo(a.createdAt);
    });

    final appointments = _showClosed
        ? service.appointments
        : service.appointments
              .where((a) => a.status == AppointmentStatus.pending)
              .toList();
    // Crisis-type requests first, then soonest preferred date.
    appointments.sort((a, b) {
      final ac = a.type == AppointmentType.crisis ? 0 : 1;
      final bc = b.type == AppointmentType.crisis ? 0 : 1;
      if (ac != bc) return ac - bc;
      return a.preferredDate.compareTo(b.preferredDate);
    });

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guidance Office',
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Hi, ${me?.fullName.isNotEmpty == true ? me!.fullName : 'Counselor'}',
                          style: textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      value: service.newAlertCount,
                      label: 'New crisis alerts',
                      color: AppColors.clayPeach,
                      icon: PhosphorIconsFill.warningCircle,
                      iconColor: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      value: service.pendingAppointmentCount,
                      label: 'Pending requests',
                      color: AppColors.claySky,
                      icon: PhosphorIconsFill.calendarDots,
                      iconColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (service.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  service.error!,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  GlassChip(
                    label: 'Crisis alerts (${service.openAlerts.length})',
                    icon: PhosphorIconsFill.warningCircle,
                    selected: _showAlerts,
                    onTap: () => setState(() => _showAlerts = true),
                  ),
                  const SizedBox(width: 10),
                  GlassChip(
                    label: 'Appointments (${service.pendingAppointmentCount})',
                    icon: PhosphorIconsFill.calendarDots,
                    selected: !_showAlerts,
                    onTap: () => setState(() => _showAlerts = false),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  _showAlerts
                      ? 'Show resolved alerts'
                      : 'Show handled requests',
                  style: textTheme.bodyMedium,
                ),
                value: _showClosed,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _showClosed = v),
              ),
              const SizedBox(height: 4),
              if (_showAlerts) ...[
                if (alerts.isEmpty)
                  const _EmptyCard(text: 'No open crisis alerts.'),
                for (final a in alerts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _AlertCard(alert: a),
                  ),
              ] else ...[
                if (appointments.isEmpty)
                  const _EmptyCard(text: 'No pending appointment requests.'),
                for (final a in appointments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _AppointmentCard(appointment: a),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  int _alertRank(CrisisAlert a) {
    if (!a.isOpen) return 3;
    if (a.status == CrisisAlertStatus.newAlert) {
      return a.source == CrisisSource.keyword ? 0 : 1;
    }
    return 2;
  }
}

/// Opens (or creates) the student's chat thread and navigates to it.
Future<void> openStudentChat(BuildContext context, String studentId) async {
  final repo = context.read<CounselorChatRepository>();
  final router = GoRouter.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final threadId = await repo.threadIdForStudent(studentId);
    router.go('/counselor/chats/$threadId?student=$studentId');
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text("Couldn't open the chat. Try again.")),
    );
  }
}

/// Asks for an optional note before a status change. Returns null if
/// cancelled, or the (possibly empty) note.
Future<String?> askNote(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String hint = 'Optional note for the record',
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(confirmLabel),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

Future<void> _run(BuildContext context, Future<void> Function() action) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text("Couldn't save that change. Try again.")),
    );
  }
}

Future<void> _openLink(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final opened = await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
  if (!opened) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not open the link.')),
    );
  }
}

/// Creates the Google Meet (on the counselor's Google Calendar, student
/// invited by email), then marks the appointment confirmed with the link.
/// If the Meet can't be created, the appointment stays pending.
Future<void> _confirmWithMeet(
  BuildContext context,
  Appointment a,
  String note,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final service = context.read<CounselorService>();
  final scheduler = context.read<MeetScheduler>();
  final student = service.student(a.userId);

  final MeetBooking booking;
  try {
    booking = await scheduler.createMeeting(
      title: 'ChatConnect counseling: ${a.subject}',
      description: [
        '${a.type.label} appointment with the WVSU Guidance Office.',
        if (a.description != null && a.description!.isNotEmpty)
          'Student\'s note: ${a.description}',
        if (note.trim().isNotEmpty) 'Counselor\'s note: ${note.trim()}',
      ].join('\n\n'),
      start: a.preferredDate,
      studentEmail: student?.email,
    );
  } catch (e) {
    debugPrint('Google Meet creation failed: $e');
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          "Couldn't create the Google Meet, so the appointment is still "
          'pending. Check the Google sign-in pop-up and try again.',
        ),
      ),
    );
    return;
  }

  try {
    await service.decideAppointment(
      a.id,
      AppointmentStatus.confirmed,
      note: note,
      meetLink: booking.meetLink,
      calendarEventLink: booking.calendarEventLink,
    );
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'The Meet was created (${booking.meetLink}) but the appointment '
          "couldn't be saved. Try confirming again.",
        ),
      ),
    );
    return;
  }
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        scheduler.isDemo
            ? 'Confirmed with a demo Meet link.'
            : 'Confirmed. Google Meet created and the student was invited by '
                  'email.',
      ),
    ),
  );
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final CrisisAlert alert;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final service = context.read<CounselorService>();
    final isKeyword = alert.source == CrisisSource.keyword;
    final student = context.watch<CounselorService>().student(alert.studentId);

    return GlassCard(
      color: alert.isOpen
          ? (isKeyword ? AppColors.clayPeach : AppColors.clayButter)
          : AppColors.claySurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isKeyword
                    ? PhosphorIconsFill.siren
                    : PhosphorIconsFill.warningCircle,
                color: isKeyword ? AppColors.error : AppColors.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isKeyword
                      ? 'Crisis keyword · SOS shown'
                      : 'Kai flagged possible crisis',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isKeyword ? AppColors.error : AppColors.tertiary,
                  ),
                ),
              ),
              Text(timeAgo(alert.createdAt), style: textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            service.studentName(alert.studentId),
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (student != null &&
              (student.studentId.isNotEmpty || student.email.isNotEmpty))
            Text(
              [
                student.studentId,
                student.email,
              ].where((s) => s.isNotEmpty).join(' · '),
              style: textTheme.labelMedium,
            ),
          if (alert.excerpt != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '"${alert.excerpt}"',
                style: textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _StatusPill(label: alert.status.label),
          if (alert.counselorNote != null) ...[
            const SizedBox(height: 6),
            Text('Note: ${alert.counselorNote}', style: textTheme.bodyMedium),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(
                icon: PhosphorIconsFill.chatCircle,
                label: 'Message',
                primary: true,
                onTap: () => openStudentChat(context, alert.studentId),
              ),
              if (alert.status == CrisisAlertStatus.newAlert)
                _ActionButton(
                  icon: PhosphorIconsBold.check,
                  label: 'Acknowledge',
                  onTap: () => _run(
                    context,
                    () => service.updateAlert(
                      alert.id,
                      CrisisAlertStatus.acknowledged,
                    ),
                  ),
                ),
              if (alert.isOpen && alert.status != CrisisAlertStatus.contacted)
                _ActionButton(
                  icon: PhosphorIconsFill.phoneCall,
                  label: 'Contacted',
                  onTap: () async {
                    final note = await askNote(
                      context,
                      title: 'Student contacted',
                      confirmLabel: 'Save',
                      hint: 'How did you reach them? (optional)',
                    );
                    if (note == null || !context.mounted) return;
                    await _run(
                      context,
                      () => service.updateAlert(
                        alert.id,
                        CrisisAlertStatus.contacted,
                        note: note,
                      ),
                    );
                  },
                ),
              if (alert.isOpen)
                _ActionButton(
                  icon: PhosphorIconsFill.checkCircle,
                  label: 'Resolve',
                  onTap: () async {
                    final note = await askNote(
                      context,
                      title: 'Resolve alert',
                      confirmLabel: 'Resolve',
                    );
                    if (note == null || !context.mounted) return;
                    await _run(
                      context,
                      () => service.updateAlert(
                        alert.id,
                        CrisisAlertStatus.resolved,
                        note: note,
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final service = context.watch<CounselorService>();
    final a = appointment;
    final isCrisis = a.type == AppointmentType.crisis;
    final when = DateFormat('EEE, MMM d · h:mm a').format(a.preferredDate);

    return GlassCard(
      color: isCrisis && a.status == AppointmentStatus.pending
          ? AppColors.clayPeach
          : AppColors.claySurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TypePill(type: a.type),
              const Spacer(),
              Text(
                'Requested ${timeAgo(a.createdAt)}',
                style: textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            a.subject,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(service.studentName(a.userId), style: textTheme.bodyMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                PhosphorIconsFill.clock,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                when,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          if (a.description != null && a.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(a.description!, style: textTheme.bodyMedium),
          ],
          if (a.meetLink != null &&
              a.status == AppointmentStatus.confirmed) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _ActionButton(
                  icon: PhosphorIconsFill.videoCamera,
                  label: 'Join Google Meet',
                  primary: true,
                  onTap: () => _openLink(context, a.meetLink!),
                ),
                if (a.calendarEventLink != null)
                  _ActionButton(
                    icon: PhosphorIconsFill.calendarBlank,
                    label: 'Open in Calendar',
                    onTap: () => _openLink(context, a.calendarEventLink!),
                  ),
                if (a.meetLink == DemoMeetScheduler.demoMeetLink)
                  Text(
                    'Demo link (Google not connected yet)',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
              ],
            ),
          ],
          if (a.status != AppointmentStatus.pending) ...[
            const SizedBox(height: 10),
            _StatusPill(
              label: a.status == AppointmentStatus.confirmed
                  ? 'Confirmed'
                  : 'Declined',
            ),
          ],
          if (a.counselorNote != null) ...[
            const SizedBox(height: 6),
            Text('Note: ${a.counselorNote}', style: textTheme.bodyMedium),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (a.status == AppointmentStatus.pending) ...[
                _ActionButton(
                  icon: PhosphorIconsBold.check,
                  label: 'Confirm',
                  primary: true,
                  onTap: () async {
                    final note = await askNote(
                      context,
                      title: 'Confirm appointment',
                      confirmLabel: 'Confirm & create Meet',
                      hint: 'Message to the student (optional)',
                    );
                    if (note == null || !context.mounted) return;
                    await _confirmWithMeet(context, a, note);
                  },
                ),
                _ActionButton(
                  icon: PhosphorIconsBold.x,
                  label: 'Decline',
                  onTap: () async {
                    final note = await askNote(
                      context,
                      title: 'Decline appointment',
                      confirmLabel: 'Decline',
                      hint: 'Reason or a better time (shown to the student)',
                    );
                    if (note == null || !context.mounted) return;
                    await _run(
                      context,
                      () => service.decideAppointment(
                        a.id,
                        AppointmentStatus.declined,
                        note: note,
                      ),
                    );
                  },
                ),
              ],
              _ActionButton(
                icon: PhosphorIconsFill.chatCircle,
                label: 'Message',
                onTap: () => openStudentChat(context, a.userId),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  final int value;
  final String label;
  final Color color;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      color: color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: textTheme.headlineLarge?.copyWith(fontSize: 28),
          ),
          Text(label, style: textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.type});

  final AppointmentType type;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (type) {
      AppointmentType.crisis => (AppColors.errorContainer, AppColors.error),
      AppointmentType.personal => (AppColors.clayLavender, AppColors.primary),
      AppointmentType.academic => (AppColors.claySky, AppColors.secondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type.label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? Colors.white : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Clay(
        borderRadius: 18,
        depth: 0.5,
        color: primary ? AppColors.primaryContainer : AppColors.claySurface,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          const Icon(PhosphorIconsFill.sparkle, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
