import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Outer clay shadows (soft purple drop + white top-left lift) for
/// containers that build their own [BoxDecoration] instead of using [Clay].
List<BoxShadow> clayShadows([double depth = 1]) => [
  BoxShadow(
    color: AppColors.clayShadow.withValues(alpha: 0.22 * depth),
    blurRadius: 28 * depth,
    offset: Offset(8 * depth, 12 * depth),
  ),
  BoxShadow(
    color: Colors.white.withValues(alpha: 0.9 * depth),
    blurRadius: 16 * depth,
    offset: Offset(-6 * depth, -6 * depth),
  ),
];

/// Claymorphism surface: a puffy, rounded shape with a soft drop shadow
/// outside plus a light highlight (top-left) and shade (bottom-right)
/// inside, so it looks like a soft pressed-clay tile.
///
/// Flutter's BoxShadow has no "inset" mode, so the inner shadows are
/// painted by [_InnerShadowPainter] behind the child.
class Clay extends StatelessWidget {
  const Clay({
    super.key,
    required this.child,
    this.color = AppColors.claySurface,
    this.borderRadius = 28,
    this.padding = EdgeInsets.zero,
    this.margin,
    this.depth = 1,
    this.shape = BoxShape.rectangle,
    this.borderColor,
  });

  final Widget child;
  final Color color;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  /// Scales shadow strength. 0 = flat, 1 = normal card, ~0.6 for small chips.
  final double depth;
  final BoxShape shape;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final isCircle = shape == BoxShape.circle;
    final radius = isCircle ? null : BorderRadius.circular(borderRadius);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        shape: shape,
        borderRadius: radius,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.5)
            : null,
        boxShadow: depth == 0
            ? null
            : [
                BoxShadow(
                  color: AppColors.clayShadow.withValues(alpha: 0.22 * depth),
                  blurRadius: 28 * depth,
                  offset: Offset(8 * depth, 12 * depth),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.9 * depth),
                  blurRadius: 16 * depth,
                  offset: Offset(-6 * depth, -6 * depth),
                ),
              ],
      ),
      child: CustomPaint(
        painter: depth == 0
            ? null
            : _InnerShadowPainter(
                radius: isCircle ? null : borderRadius,
                depth: depth,
                baseColor: color,
              ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _InnerShadowPainter extends CustomPainter {
  _InnerShadowPainter({
    required this.radius,
    required this.depth,
    required this.baseColor,
  });

  /// null means a circle.
  final double? radius;
  final double depth;
  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = radius == null
        ? RRect.fromRectAndRadius(rect, Radius.circular(size.shortestSide / 2))
        : RRect.fromRectAndRadius(rect, Radius.circular(radius!));

    canvas.save();
    canvas.clipRRect(rrect);
    // Highlight along the top-left inner edge.
    _inner(
      canvas,
      rect,
      rrect,
      Colors.white.withValues(alpha: 0.85),
      Offset(5 * depth, 5 * depth),
      8 * depth,
    );
    // Shade along the bottom-right inner edge, tinted from the fill colour.
    final shade = Color.lerp(baseColor, AppColors.clayShadow, 0.5)!;
    _inner(
      canvas,
      rect,
      rrect,
      shade.withValues(alpha: 0.28),
      Offset(-6 * depth, -6 * depth),
      12 * depth,
    );
    canvas.restore();
  }

  void _inner(
    Canvas canvas,
    Rect rect,
    RRect rrect,
    Color color,
    Offset offset,
    double blur,
  ) {
    final paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(blur * 3))
      ..addRRect(rrect.shift(offset));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_InnerShadowPainter old) =>
      old.radius != radius || old.depth != depth || old.baseColor != baseColor;
}
