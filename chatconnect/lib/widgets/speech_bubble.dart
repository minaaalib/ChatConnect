import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Which edge of the bubble the pointer tail sticks out of, and therefore
/// what it's "pointing at": [bottom] sits above whatever it's spoken by,
/// [right] sits to the left of it with the tail aimed at e.g. a mouth.
enum BubbleTailSide { bottom, right }

/// A chat-style bubble with a triangular pointer tail — see [BubbleTailSide]
/// for where it sits relative to whatever it's "spoken" by (see
/// [InteractiveMascot]).
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    this.moodLabel,
    this.tailSide = BubbleTailSide.bottom,
    this.maxWidth = 200,
    this.fontSize = 13,
    this.premium = false,
  });

  final String text;

  /// One of the dashboard mood labels ("Happy", "Okay", "Sad", "Angry",
  /// "Anxious") — tints the bubble to match. Null/unrecognized falls back
  /// to the default lavender gradient. Ignored when [premium] is true.
  final String? moodLabel;

  final BubbleTailSide tailSide;

  /// Caps the bubble's width — the default suits a small floating thought
  /// bubble; pass `double.infinity` when wrapping this in an [Expanded]
  /// inside a [Row] so it fills the space instead (e.g. the dashboard's
  /// quote-of-the-day bubble).
  final double maxWidth;

  final double fontSize;

  /// Swaps the playful mood-tinted gradient for a flat white "premium" card
  /// look — soft diffuse shadow, no border, dark-grey sans-serif text, and a
  /// smaller/smoother tail. Used by content-forward bubbles like the
  /// dashboard's quote-of-the-day card, where a bright mood gradient would
  /// clash with the surrounding purple background rather than read as calm.
  final bool premium;

  static const _gradients = {
    'Happy': [Color(0xFFFFF4D6), Color(0xFFFFD98F)],
    'Okay': [Color(0xFFFFFFFF), Color(0xFFE6DDFD)],
    'Sad': [Color(0xFFEAF2FB), Color(0xFFC2D8EF)],
    'Angry': [Color(0xFFFCE7E4), Color(0xFFEFB6AA)],
    'Anxious': [Color(0xFFF3EDF9), Color(0xFFD6C3E8)],
  };

  List<Color> get _colors => _gradients[moodLabel] ?? _gradients['Okay']!;

  static const _premiumColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    final tailColor = premium ? _premiumColor : colors.last;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: premium
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
          : const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: premium ? _premiumColor : null,
        gradient: premium
            ? null
            : LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(18),
        border: premium
            ? null
            : Border.all(
                color: AppColors.primaryContainer.withValues(alpha: 0.4),
              ),
        boxShadow: premium
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x293A2456),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: premium
            ? GoogleFonts.quicksand(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
                height: 1.4,
              )
            : GoogleFonts.quicksand(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: AppColors.onSurface,
                height: 1.3,
              ),
      ),
    );

    final tail = CustomPaint(
      size: tailSide == BubbleTailSide.bottom
          ? (premium ? const Size(14, 7) : const Size(16, 8))
          : (premium ? const Size(7, 14) : const Size(8, 16)),
      painter: _BubbleTailPainter(
        color: tailColor,
        side: tailSide,
        bordered: !premium,
      ),
    );

    if (tailSide == BubbleTailSide.bottom) {
      return Column(mainAxisSize: MainAxisSize.min, children: [bubble, tail]);
    }

    // maxWidth == infinity signals the "fill the row" mode (the dashboard's
    // large quote bubble) — Expanded there, so it grows to fill whatever
    // finite width its own parent Row gives it. Natural sizing otherwise
    // (the small floating thought bubble), since that's rendered inside an
    // UnconstrainedBox with unbounded width, where Expanded would crash.
    return maxWidth.isInfinite
        ? Row(
            children: [
              Expanded(child: bubble),
              tail,
            ],
          )
        : Row(mainAxisSize: MainAxisSize.min, children: [bubble, tail]);
  }
}

class _BubbleTailPainter extends CustomPainter {
  _BubbleTailPainter({
    required this.color,
    required this.side,
    this.bordered = true,
  });

  final Color color;
  final BubbleTailSide side;

  /// Premium bubbles skip the outline for a softer, smoother tail that
  /// reads as part of the bubble rather than a separate decorated shape.
  final bool bordered;

  @override
  void paint(Canvas canvas, Size size) {
    final path = side == BubbleTailSide.bottom
        ? (Path()
            ..moveTo(0, 0)
            ..lineTo(size.width, 0)
            ..lineTo(size.width / 2, size.height)
            ..close())
        : (Path()
            ..moveTo(0, 0)
            ..lineTo(0, size.height)
            ..lineTo(size.width, size.height / 2)
            ..close());

    canvas.drawPath(path, Paint()..color = color);
    if (bordered) {
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.primaryContainer.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.side != side ||
      oldDelegate.bordered != bordered;
}
