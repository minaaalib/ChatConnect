import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../constants/crisis_contacts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/crisis_contact_button.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';

/// Full-screen counterpart to [SosOverlay], reached directly without a
/// signed-in session's navigation chrome — the entry point for the Home
/// Screen Widget's SOS button (`chatconnect://sos`) and any other
/// cold-launch deep link that needs to land a student on crisis resources
/// immediately, with no app browsing in between.
class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => context.go('/dashboard'),
                  icon: const Icon(
                    PhosphorIconsBold.arrowLeft,
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('🆘', style: TextStyle(fontSize: 28)),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "You're not alone right now",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'If this is urgent, please reach out to one of these '
                            'right now, or connect with a counselor in the app '
                            'immediately.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                            ),
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
                              onPressed: () =>
                                  context.go('/chat/session-counselor-1'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text(
                                'Connect me to a counselor now',
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/dashboard'),
                            child: const Text(
                              "I'm safe for now, take me to the app",
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
