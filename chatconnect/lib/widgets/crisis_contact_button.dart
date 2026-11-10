import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/crisis_contacts.dart';
import '../theme/app_colors.dart';

/// Shared by [SosOverlay] and [SosScreen] — a full-width tap-to-call button
/// for one [CrisisContact], disabled (not guessing a number) when unconfigured.
class CrisisContactButton extends StatelessWidget {
  const CrisisContactButton({super.key, required this.contact});

  final CrisisContact contact;

  bool get _isConfigured =>
      contact.phone != null && contact.phone!.trim().isNotEmpty;

  Future<void> _call(BuildContext context) async {
    if (!_isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${contact.label} number is not configured yet.'),
        ),
      );
      return;
    }
    await launchUrl(Uri(scheme: 'tel', path: contact.phone));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _call(context),
        icon: Icon(
          PhosphorIconsFill.phoneCall,
          color: _isConfigured ? AppColors.tertiary : AppColors.outline,
        ),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _isConfigured
                ? '${contact.label} · ${contact.phone}'
                : '${contact.label} (not configured)',
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _isConfigured
              ? AppColors.tertiary
              : AppColors.outline,
          side: BorderSide(
            color: _isConfigured
                ? AppColors.crisisBorder
                : AppColors.outlineVariant,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      ),
    );
  }
}
