import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../theme/app_colors.dart';

/// Shown when a message is flagged as a crisis alert. Deliberately cannot be
/// fully dismissed back to a normal chat bubble: choosing "No, continue with
/// Kai" collapses this into a persistent compact resource strip instead of
/// disappearing, so a student who declines counselor contact once still has
/// a visible way back to it for the rest of the conversation.
class CrisisAlertCard extends StatefulWidget {
  const CrisisAlertCard({
    super.key,
    required this.onConnect,
    required this.onContinue,
  });

  /// Called whenever the student asks to be connected to a human counselor,
  /// whether from the initial prompt or the persistent strip afterward.
  final VoidCallback onConnect;

  /// Called once, the first time the student chooses to continue with Kai
  /// instead of connecting. The card stays visible in collapsed form
  /// regardless — this is for logging/analytics, not for hiding the UI.
  final VoidCallback onContinue;

  @override
  State<CrisisAlertCard> createState() => _CrisisAlertCardState();
}

enum _CrisisCardView { prompt, connecting, collapsed }

class _CrisisAlertCardState extends State<CrisisAlertCard> {
  var _view = _CrisisCardView.prompt;

  void _handleConnect() {
    widget.onConnect();
    setState(() => _view = _CrisisCardView.connecting);
  }

  void _handleContinue() {
    widget.onContinue();
    setState(() => _view = _CrisisCardView.collapsed);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.crisisBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.crisisBorder),
      ),
      child: switch (_view) {
        _CrisisCardView.prompt => _PromptView(
          onConnect: _handleConnect,
          onContinue: _handleContinue,
        ),
        _CrisisCardView.connecting => const _ConnectingView(),
        _CrisisCardView.collapsed => _CollapsedView(onConnect: _handleConnect),
      },
    );
  }
}

class _PromptView extends StatelessWidget {
  const _PromptView({required this.onConnect, required this.onContinue});

  final VoidCallback onConnect;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🆘', style: TextStyle(fontSize: 22)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "I'm here for you.",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.tertiary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "It sounds like you're going through a lot. Would you "
                    'like to talk to a human counselor right now?',
                    style: TextStyle(fontSize: 12, color: AppColors.tertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _CrisisContactStrip(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onConnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tertiary,
                  foregroundColor: AppColors.onTertiary,
                ),
                child: const Text('Yes, connect me'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton(
                onPressed: onContinue,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.tertiary,
                ),
                child: const Text('No, continue with Kai'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConnectingView extends StatelessWidget {
  const _ConnectingView();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.tertiary,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            "Connecting you with a counselor. Kai stays with you until "
            'someone joins.',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.tertiary,
            ),
          ),
        ),
      ],
    );
  }
}

/// The fallback state — replaces the old "just disappears" behavior. Stays
/// in the chat transcript for the rest of the session instead of quietly
/// reverting to a normal conversation with no safety net.
class _CollapsedView extends StatelessWidget {
  const _CollapsedView({required this.onConnect});

  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          PhosphorIconsFill.heart,
          size: 18,
          color: AppColors.tertiary,
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Support is still here whenever you want it.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.tertiary,
            ),
          ),
        ),
        TextButton(
          onPressed: onConnect,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.tertiary,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: const Text('Talk to someone', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

/// TODO(product): replace with WVSU Guidance Office's actual verified crisis
/// contact info before this ships to real users — do not launch with a
/// placeholder number here.
class _CrisisContactStrip extends StatelessWidget {
  const _CrisisContactStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(
            PhosphorIconsFill.phoneCall,
            size: 16,
            color: AppColors.tertiary,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'WVSU Guidance Office crisis line: [contact info pending]',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.tertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
