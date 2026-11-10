import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../theme/app_colors.dart';
import '../../widgets/clay.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_chip.dart';
import '../../widgets/gradient_background.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        GlassChip(
                          label: 'AI-Powered Mental Health',
                          icon: PhosphorIconsFill.robot,
                        ),
                        GlassChip(
                          label: '24/7 Available',
                          icon: PhosphorIconsFill.circle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    GlassCard(
                      borderRadius: 28,
                      child: Column(
                        children: [
                          Image.asset('assets/logo.png', height: 72),
                          const SizedBox(height: 4),
                          Text(
                            'Your safe space. Always.',
                            style: textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'A private space to care for your mental '
                            'wellbeing with Kai, the AI companion that '
                            'understands you.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.clayLavender,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: clayShadows(0.5),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      PhosphorIconsFill.sparkle,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Join 1,200+ students already using '
                                        'ChatConnect',
                                        textAlign: TextAlign.center,
                                        style: textTheme.labelMedium?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '🌟 94% of users feel better after their '
                                  'first chat',
                                  style: textTheme.labelMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              GlassChip(
                                label: '24/7 AI Support',
                                icon: PhosphorIconsFill.waves,
                              ),
                              GlassChip(
                                label: 'Private & Safe',
                                icon: PhosphorIconsFill.shieldCheck,
                              ),
                              GlassChip(
                                label: 'Personalized',
                                icon: PhosphorIconsFill.target,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(PhosphorIconsBold.arrowRight),
                        label: const Text('Start Your Wellbeing Journey'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Free for all WVSU students · 2 minutes to start',
                      style: textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'Already have an account? Log in',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassChip(
                      label:
                          'Your conversations are confidential · WVSU '
                          'Guidance Office',
                      icon: PhosphorIconsFill.lockKey,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
