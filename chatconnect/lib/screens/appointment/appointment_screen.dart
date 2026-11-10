import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/appointment.dart';
import '../../services/appointment_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  AppointmentType _type = AppointmentType.academic;
  DateTime? _preferredDate;
  TimeOfDay? _preferredTime;
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isBooking = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _preferredDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _preferredTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _preferredTime = picked);
  }

  Future<void> _submit() async {
    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please give this appointment a subject.'),
        ),
      );
      return;
    }
    if (_preferredDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a preferred date first.')),
      );
      return;
    }
    if (_preferredTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a preferred time first.')),
      );
      return;
    }
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();
    final preferredDateTime = DateTime(
      _preferredDate!.year,
      _preferredDate!.month,
      _preferredDate!.day,
      _preferredTime!.hour,
      _preferredTime!.minute,
    );

    setState(() => _isBooking = true);
    try {
      await context.read<AppointmentService>().requestAppointment(
        type: _type,
        subject: subject,
        preferredDate: preferredDateTime,
        description: description,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isBooking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't send your request to the Guidance Office. Check your "
            'connection and try again.',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _isBooking = false;
      _preferredDate = null;
      _preferredTime = null;
      _subjectController.clear();
      _descriptionController.clear();
      _type = AppointmentType.academic;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Request sent. You'll get a Google Meet link once a counselor "
          'confirms it.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _AppointmentHeader(
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book a session with the Guidance Office',
                            style: textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This connects you with a real WVSU Guidance '
                            'Counselor — Kai cannot hold this appointment '
                            'for you.',
                            style: textTheme.labelMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Appointment type',
                            style: textTheme.labelMedium,
                          ),
                          const SizedBox(height: 8),
                          _TypeDropdown(
                            value: _type,
                            onChanged: (v) => setState(() => _type = v),
                          ),
                          if (_type == AppointmentType.crisis) ...[
                            const SizedBox(height: 10),
                            _CrisisNotice(),
                          ],
                          const SizedBox(height: 16),
                          Text('Subject', style: textTheme.labelMedium),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _subjectController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Trouble coping with coursework',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Preferred date', style: textTheme.labelMedium),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: _PickerButton(
                              icon: PhosphorIconsFill.calendarBlank,
                              label: _preferredDate == null
                                  ? 'Choose a date'
                                  : DateFormat.yMMMd().format(_preferredDate!),
                              onTap: _pickDate,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Preferred time', style: textTheme.labelMedium),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: _PickerButton(
                              icon: PhosphorIconsFill.clock,
                              label: _preferredTime == null
                                  ? 'Choose a time'
                                  : _preferredTime!.format(context),
                              onTap: _pickTime,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Description (optional)',
                            style: textTheme.labelMedium,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText:
                                  'Anything you want the counselor to know ahead of time',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Booking signs you into your own Google account to '
                            'create the event and generate a Meet link.',
                            style: textTheme.labelMedium?.copyWith(
                              color: AppColors.outline,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isBooking ? null : _submit,
                              child: _isBooking
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.onPrimaryContainer,
                                      ),
                                    )
                                  : const Text('Request appointment'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Your requests', style: textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    Consumer<AppointmentService>(
                      builder: (context, service, _) {
                        if (service.appointments.isEmpty) {
                          return Text(
                            'No appointment requests yet.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          );
                        }
                        return Column(
                          children: [
                            for (final a in service.appointments)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _AppointmentTile(appointment: a),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentHeader extends StatelessWidget {
  const _AppointmentHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              PhosphorIconsBold.arrowLeft,
              color: AppColors.primary,
            ),
          ),
          const Icon(PhosphorIconsFill.calendarBlank, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Book Counselor', style: textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  const _TypeDropdown({required this.value, required this.onChanged});

  final AppointmentType value;
  final ValueChanged<AppointmentType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AppointmentType>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            PhosphorIconsBold.caretDown,
            size: 18,
            color: AppColors.outline,
          ),
          items: [
            for (final t in AppointmentType.values)
              DropdownMenuItem(value: t, child: Text(t.label)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

class _CrisisNotice extends StatelessWidget {
  const _CrisisNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.crisisBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.crisisBorder),
      ),
      child: const Row(
        children: [
          Icon(PhosphorIconsFill.warning, color: AppColors.tertiary, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "If you're in immediate danger, don't wait for this "
              'appointment — use the SOS button in chat or contact campus '
              'security right now.',
              style: TextStyle(fontSize: 12, color: AppColors.tertiary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.appointment});

  final Appointment appointment;

  String get _statusLabel => switch (appointment.status) {
    AppointmentStatus.pending => 'Pending Guidance Office confirmation',
    AppointmentStatus.confirmed => 'Confirmed — ready for your session',
    AppointmentStatus.declined => 'Declined by the Guidance Office',
  };

  Future<void> _openLink(BuildContext context, String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open the link.')));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: appointment.type == AppointmentType.crisis
                ? AppColors.crisisBackground
                : AppColors.surfaceTint,
            child: Icon(
              appointment.type == AppointmentType.crisis
                  ? PhosphorIconsFill.warning
                  : PhosphorIconsFill.calendarCheck,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.subject,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${appointment.type.label} · ${DateFormat.yMMMd().add_jm().format(appointment.preferredDate)}',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _statusLabel,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.outline,
                  ),
                ),
                if (appointment.counselorNote != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Guidance Office: ${appointment.counselorNote}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (appointment.status == AppointmentStatus.confirmed &&
                    appointment.meetLink != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            _openLink(context, appointment.meetLink!),
                        icon: const Icon(
                          PhosphorIconsFill.videoCamera,
                          size: 16,
                        ),
                        label: const Text('Join Google Meet'),
                      ),
                      if (appointment.calendarEventLink != null)
                        OutlinedButton.icon(
                          onPressed: () => _openLink(
                            context,
                            appointment.calendarEventLink!,
                          ),
                          icon: const Icon(
                            PhosphorIconsFill.calendarBlank,
                            size: 16,
                          ),
                          label: const Text('View in Calendar'),
                        ),
                    ],
                  ),
                ] else if (appointment.status == AppointmentStatus.pending) ...[
                  const SizedBox(height: 4),
                  Text(
                    'The Google Meet link will appear here once a counselor '
                    'confirms.',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.tertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
