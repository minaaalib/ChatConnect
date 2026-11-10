import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Soft lavender page background for the claymorphism look: a gentle
/// diagonal gradient so clay tiles have a tinted base to cast shadows on.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6F1FD), AppColors.background, Color(0xFFEDE6FA)],
        ),
      ),
      child: child,
    );
  }
}
