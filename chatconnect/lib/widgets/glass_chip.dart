import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'clay.dart';

class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.selected = false,
    this.foregroundColor,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool selected;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? AppColors.primary;
    return Clay(
      borderRadius: 999,
      depth: 0.55,
      color: selected ? AppColors.primaryContainer : AppColors.claySurface,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected ? AppColors.onPrimaryContainer : fg,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.onPrimaryContainer : fg,
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
