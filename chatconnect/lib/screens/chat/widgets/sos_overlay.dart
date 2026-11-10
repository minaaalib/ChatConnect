import 'package:flutter/material.dart';

import '../../../constants/crisis_contacts.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/crisis_contact_button.dart';

/// Shown as a full-screen, barrier-dismiss-disabled dialog the moment the
/// backend's hardcoded keyword filter (not the LLM) flags a message —
/// see [ChatMessage.sosTriggered]. Deliberately heavier-weight than
/// [CrisisAlertCard]: this is the hard-signal path, so it interrupts rather
/// than waits to be noticed inline.
class SosOverlay extends StatelessWidget {
  const SosOverlay({super.key, required this.onConnectCounselor});

  final VoidCallback onConnectCounselor;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onConnectCounselor,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SosOverlay(onConnectCounselor: onConnectCounselor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('🆘', style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "You're not alone right now",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'What you shared sounds really serious. Please reach out to '
              'one of these right now, or connect with a counselor in the '
              'app immediately.',
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            for (final contact in CrisisContacts.all)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CrisisContactButton(contact: contact),
              ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConnectCounselor();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Connect me to a counselor now'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "I'm safe for now, let me continue",
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
