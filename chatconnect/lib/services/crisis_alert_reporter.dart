import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/crisis_alert.dart';

/// Raises a crisis alert for the Guidance Office when Kai chat detects a
/// crisis. Called from the student's chat screen.
///
/// Keyword (hard) hits are always sent. AI (soft) flags are limited to one
/// per 10 minutes so a single hard conversation doesn't flood the inbox.
abstract class CrisisAlertReporter {
  DateTime? _lastAiAlert;

  static const _aiCooldown = Duration(minutes: 10);
  static const _maxExcerpt = 500;

  Future<void> report({
    required CrisisSource source,
    required String studentMessage,
  }) async {
    if (source == CrisisSource.ai) {
      final last = _lastAiAlert;
      if (last != null && DateTime.now().difference(last) < _aiCooldown) {
        return;
      }
      _lastAiAlert = DateTime.now();
    }
    final excerpt = studentMessage.length > _maxExcerpt
        ? studentMessage.substring(0, _maxExcerpt)
        : studentMessage;
    await save(source: source, excerpt: excerpt);
  }

  @protected
  Future<void> save({required CrisisSource source, required String excerpt});
}

class SupabaseCrisisAlertReporter extends CrisisAlertReporter {
  SupabaseCrisisAlertReporter(this._client);

  final SupabaseClient _client;

  @override
  Future<void> save({
    required CrisisSource source,
    required String excerpt,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    // One retry: losing a crisis alert to a network blip matters more than
    // a rare duplicate.
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        await _client.from('crisis_alerts').insert({
          'student_id': userId,
          'source': source.name,
          'excerpt': excerpt,
        });
        return;
      } catch (e) {
        debugPrint('Crisis alert insert failed (attempt ${attempt + 1}): $e');
        if (attempt == 0) await Future.delayed(const Duration(seconds: 2));
      }
    }
  }
}
