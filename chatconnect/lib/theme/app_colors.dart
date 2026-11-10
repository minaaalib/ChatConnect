import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF5B3A8C);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF7C5DAD);
  static const onPrimaryContainer = Color(0xFFFDFBFF);

  static const secondary = Color(0xFF6B4C8F);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFE0D3F7);
  static const onSecondaryContainer = Color(0xFF4A3268);

  static const tertiary = Color(0xFF8C4A3E);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFAA6254);
  static const tertiaryFixedDim = Color(0xFFFFB4A6);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const background = Color(0xFFF1ECFA);
  static const onBackground = Color(0xFF1E1329);
  static const surface = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF1E1329);
  static const onSurfaceVariant = Color(0xFF4A4152);

  static const surfaceContainerLow = Color(0xFFF2EBFD);
  static const surfaceContainer = Color(0xFFE6DDFD);
  static const surfaceContainerHigh = Color(0xFFDDD0FB);
  static const surfaceContainerHighest = Color(0xFFD3C3F9);

  static const outline = Color(0xFF7A7080);
  static const outlineVariant = Color(0xFFCBC0CF);

  /// Light lavender panel fill — used instead of translucent white for any
  /// surface that needs to read as distinct from the flat white page
  /// background (white-on-white would otherwise be invisible).
  static const surfaceTint = Color(0xFFF7F3FD);
  static const borderSubtle = Color(0xFFE6E0F2);

  // Claymorphism palette: pastel fills on a lavender page, with a purple
  // shadow tone so shadows read as soft clay rather than grey drop shadows.
  static const claySurface = Color(0xFFFBF9FF);
  static const clayShadow = Color(0xFF7B5FB0);
  static const clayLavender = Color(0xFFE4D9FA);
  static const clayPeach = Color(0xFFFFE1D6);
  static const clayMint = Color(0xFFD6F2E6);
  static const claySky = Color(0xFFD8E8FB);
  static const clayButter = Color(0xFFFFF0C8);

  static const crisisBackground = Color(0x33D9897A);
  static const crisisBorder = Color(0x66D9897A);

  /// Marks a human (not AI) presence — e.g. the counselor badge — so it
  /// reads as distinct from Kai's purple "AI" badge at a glance.
  static const verified = Color(0xFF2E7D32);
  static const verifiedContainer = Color(0xFFE3F2E6);
}
