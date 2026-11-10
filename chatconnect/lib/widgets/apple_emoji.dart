import 'package:flutter/material.dart';

/// Shows a mood emoji in Apple's style on every platform, using PNGs bundled
/// in `assets/emoji/` (from the emoji-datasource-apple package). Android has
/// no Apple emoji font, so plain text would render in Google's style.
///
/// Note: Apple's emoji artwork isn't licensed for use outside Apple
/// platforms. Fine for the thesis demo; swap the PNGs before a store release.
class AppleEmoji extends StatelessWidget {
  const AppleEmoji(this.emoji, {super.key, this.size = 24});

  final String emoji;
  final double size;

  static const _assets = <String, String>{
    '😊': 'assets/emoji/1f60a.png',
    '😐': 'assets/emoji/1f610.png',
    '😔': 'assets/emoji/1f614.png',
    '😡': 'assets/emoji/1f621.png',
    '😰': 'assets/emoji/1f630.png',
  };

  static bool supports(String? emoji) => _assets.containsKey(emoji);

  @override
  Widget build(BuildContext context) {
    final asset = _assets[emoji];
    if (asset == null) {
      // Unknown emoji: fall back to the system font.
      return Text(emoji, style: TextStyle(fontSize: size * 0.85, height: 1));
    }
    return Image.asset(
      asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: emoji,
    );
  }
}
