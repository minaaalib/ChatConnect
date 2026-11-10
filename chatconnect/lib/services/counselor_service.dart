import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/appointment.dart';
import '../models/counselor_thread.dart';
import '../models/crisis_alert.dart';
import '../models/user_profile.dart';
import 'auth_service.dart';

/// Everything the counselor's inbox shows: crisis alerts, appointment
/// requests and student chat threads. Lists are newest first.
///
/// Two implementations: [SupabaseCounselorService] (real, live) and
/// DemoCounselorService (offline sample data, see services/demo/).
abstract class CounselorService extends ChangeNotifier {
  List<CrisisAlert> get alerts;
  List<Appointment> get appointments;
  List<CounselorThread> get threads;

  /// Set when the live connection drops.
  String? get error => null;

  UserProfile? student(String id);

  Future<void> updateAlert(
    String alertId,
    CrisisAlertStatus status, {
    String? note,
  });

  /// [meetLink]/[calendarEventLink] come from the Google Meet created when
  /// confirming (see MeetScheduler).
  Future<void> decideAppointment(
    String appointmentId,
    AppointmentStatus status, {
    String? note,
    String? meetLink,
    String? calendarEventLink,
  });

  String studentName(String id) {
    final name = student(id)?.fullName ?? '';
    return name.isEmpty ? 'Student' : name;
  }

  List<CrisisAlert> get openAlerts => alerts.where((a) => a.isOpen).toList();
  int get newAlertCount =>
      alerts.where((a) => a.status == CrisisAlertStatus.newAlert).length;
  int get pendingAppointmentCount =>
      appointments.where((a) => a.status == AppointmentStatus.pending).length;
  int get threadsAwaitingReply =>
      threads.where((t) => t.awaitingCounselor).length;

  /// Red badge on the Inbox tab.
  int get inboxBadge => newAlertCount + pendingAppointmentCount;
}

/// Live version backed by Supabase Realtime. Only subscribes while a
/// counselor is signed in.
class SupabaseCounselorService extends CounselorService {
  SupabaseCounselorService(this._client, this._auth) {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final SupabaseClient _client;
  final AuthService _auth;

  final _subs = <StreamSubscription<dynamic>>[];
  bool _active = false;

  List<CrisisAlert> _alerts = [];
  List<Appointment> _appointments = [];
  List<CounselorThread> _threads = [];
  final _students = <String, UserProfile>{};
  final _loadingStudents = <String>{};
  String? _error;

  @override
  List<CrisisAlert> get alerts => _alerts;
  @override
  List<Appointment> get appointments => _appointments;
  @override
  List<CounselorThread> get threads => _threads;
  @override
  String? get error => _error;
  @override
  UserProfile? student(String id) => _students[id];

  void _onAuthChanged() {
    final shouldBeActive = _auth.currentUser?.isCounselor ?? false;
    if (shouldBeActive == _active) return;
    _active = shouldBeActive;
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _alerts = [];
    _appointments = [];
    _threads = [];
    _students.clear();
    _error = null;
    if (_active) _subscribe();
    notifyListeners();
  }

  void _subscribe() {
    void onError(Object e) {
      _error = 'Lost connection to the server. Reopen the app to retry.';
      debugPrint('CounselorService stream error: $e');
      notifyListeners();
    }

    _subs.add(
      _client
          .from('crisis_alerts')
          .stream(primaryKey: ['id'])
          .order('created_at')
          .limit(200)
          .listen((rows) {
            _alerts = rows.map(CrisisAlert.fromRow).toList();
            _afterUpdate(_alerts.map((a) => a.studentId));
          }, onError: onError),
    );
    _subs.add(
      _client
          .from('appointments')
          .stream(primaryKey: ['id'])
          .order('created_at')
          .limit(200)
          .listen((rows) {
            _appointments = rows.map(Appointment.fromRow).toList();
            _afterUpdate(_appointments.map((a) => a.userId));
          }, onError: onError),
    );
    _subs.add(
      _client
          .from('counselor_threads')
          .stream(primaryKey: ['id'])
          .order('last_message_at')
          .limit(200)
          .listen((rows) {
            _threads = rows.map(CounselorThread.fromRow).toList();
            _afterUpdate(_threads.map((t) => t.studentId));
          }, onError: onError),
    );
  }

  void _afterUpdate(Iterable<String> studentIds) {
    _error = null;
    notifyListeners();
    _loadStudents(studentIds);
  }

  Future<void> _loadStudents(Iterable<String> ids) async {
    final missing = ids
        .where(
          (id) => !_students.containsKey(id) && !_loadingStudents.contains(id),
        )
        .toSet()
        .toList();
    if (missing.isEmpty) return;
    _loadingStudents.addAll(missing);
    try {
      final rows = await _client
          .from('profiles')
          .select()
          .inFilter('id', missing);
      for (final row in rows) {
        final p = UserProfile.fromRow(row);
        _students[p.id] = p;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Could not load student profiles: $e');
    } finally {
      _loadingStudents.removeAll(missing);
    }
  }

  @override
  Future<void> updateAlert(
    String alertId,
    CrisisAlertStatus status, {
    String? note,
  }) async {
    await _client
        .from('crisis_alerts')
        .update({
          'status': status.dbValue,
          'handled_by': _client.auth.currentUser?.id,
          if (note != null && note.trim().isNotEmpty)
            'counselor_note': note.trim(),
        })
        .eq('id', alertId);
  }

  @override
  Future<void> decideAppointment(
    String appointmentId,
    AppointmentStatus status, {
    String? note,
    String? meetLink,
    String? calendarEventLink,
  }) async {
    await _client
        .from('appointments')
        .update({
          'status': status.name,
          'handled_by': _client.auth.currentUser?.id,
          if (note != null && note.trim().isNotEmpty)
            'counselor_note': note.trim(),
          'meet_link': ?meetLink,
          'calendar_event_link': ?calendarEventLink,
        })
        .eq('id', appointmentId);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
