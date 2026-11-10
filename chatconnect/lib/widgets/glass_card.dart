import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'clay.dart';

/// The app's standard card. Historically glassmorphism (hence the name,
/// kept so existing screens don't change); now a claymorphism [Clay] tile.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 28,
    this.opacity = 1,
    this.borderColor,
    this.margin,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  // Lower values blend the card fill toward the page background.
  final double opacity;
  // Ignored by the clay style (clay tiles have no outline); kept so
  // existing callers still compile.
  final Color? borderColor;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Clay(
      margin: margin,
      padding: padding,
      borderRadius: borderRadius,
      color: Color.lerp(
        AppColors.background,
        color ?? AppColors.claySurface,
        opacity,
      )!,
      child: child,
    );
  }
}
