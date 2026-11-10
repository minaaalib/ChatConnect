import 'package:flutter/foundation.dart';
import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../constants/mental_health_quotes.dart';

/// Pushes data to the Android/iOS Home Screen Widget and resolves the deep
/// links it can launch the app with. The widget itself is native code
/// (`android/.../ChatConnectWidgetProvider.kt` on Android, a WidgetKit
/// extension on iOS) — this class is only the Flutter-side half of the
/// handshake `home_widget` provides.
class HomeWidgetService {
  HomeWidgetService._();

  /// Must match the Kotlin class name in
  /// `android/.../ChatConnectWidgetProvider.kt`.
  static const _androidProviderName = 'ChatConnectWidgetProvider';

  /// Must match the `kind` string the iOS Widget declares in its
  /// `WidgetConfiguration` (see the iOS setup notes).
  static const _iOSWidgetName = 'ChatConnectWidget';

  /// Must match the App Group ID shared between the Runner app target and
  /// the Widget Extension target in Xcode — only meaningful on iOS.
  static const _iOSAppGroupId = 'group.ph.edu.wvsu.chatconnect';

  static const _quoteTextKey = 'quote_text';
  static const _quoteAuthorKey = 'quote_author';
  static const _moodLabelKey = 'mood_label';

  /// Call once at app startup, before any other [HomeWidgetService] method —
  /// iOS needs the App Group ID to read/write the storage it shares with the
  /// Widget Extension. No-op on Android.
  static Future<void> initialize() async {
    if (kIsWeb) return; // No home screen widgets on the web.
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(_iOSAppGroupId);
    }
  }

  /// Writes today's quote to widget storage and asks the OS to redraw the
  /// widget. Call this whenever the in-app quote could have changed —
  /// currently just once, from [AppRouterProvider]'s `initState`, since
  /// there's no background refresh wired up yet (see README note on daily
  /// refresh).
  static Future<void> pushQuoteOfTheDay() async {
    if (kIsWeb) return;
    final quote = MentalHealthQuotes.quoteOfTheDay();
    await HomeWidget.saveWidgetData<String>(_quoteTextKey, quote.text);
    await HomeWidget.saveWidgetData<String>(
      _quoteAuthorKey,
      '— ${quote.author}',
    );
    await HomeWidget.updateWidget(
      androidName: _androidProviderName,
      iOSName: _iOSWidgetName,
    );
  }

  /// Writes the most recently logged mood label (e.g. "Happy", "Anxious")
  /// so the native widget can tint its background to match — see the
  /// `moodLabel` switch in `ChatConnectWidgetProvider.kt`. Call this
  /// whenever [MoodService.logMood] records a new entry.
  static Future<void> pushLatestMood(String label) async {
    if (kIsWeb) return;
    await HomeWidget.saveWidgetData<String>(_moodLabelKey, label);
    await HomeWidget.updateWidget(
      androidName: _androidProviderName,
      iOSName: _iOSWidgetName,
    );
  }

  /// True when [uri] is the widget's SOS button, e.g. `chatconnect://sos`.
  static bool isSosLaunch(Uri? uri) => uri?.host == 'sos';
}
