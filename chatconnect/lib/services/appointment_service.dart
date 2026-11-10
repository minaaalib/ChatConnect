import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/appointment.dart';
import 'auth_service.dart';
import 'demo/demo_store.dart';

/// The student's own appointment requests.
///
/// With Supabase configured, requests go to the `appointments` table and
/// the list updates live as a counselor confirms or declines them. In the
/// offline demo they go into this app's own [DemoStore] (the counselor web
/// app has its own sample data). The Google Meet link is added by the
/// counselor app when the appointment is confirmed.
class AppointmentService extends ChangeNotifier {
  AppointmentService({
    SupabaseClient? client,
    DemoStore? demoStore,
    required AuthService auth,
  }) : _client = client,
       _store = demoStore,
       _auth = auth {
    _auth.addListener(_onAuthChanged);
    _store?.addListener(notifyListeners);
    _onAuthChanged();
  }

  final SupabaseClient? _client;
  final DemoStore? _store;
  final AuthService _auth;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  String? _subscribedUserId;
  List<Appointment> _appointments = [];

  List<Appointment> get appointments {
    final store = _store;
    if (store != null) {
      final me = _auth.currentUser?.id;
      return store.appointments.where((a) => a.userId == me).toList();
    }
    return List.unmodifiable(_appointments);
  }

  void _onAuthChanged() {
    final client = _client;
    if (client == null) {
      notifyListeners();
      return;
    }
    final user = _auth.currentUser;
    final userId = (user == null || user.isCounselor) ? null : user.id;
    if (userId == _subscribedUserId) return;

    _sub?.cancel();
    _sub = null;
    _subscribedUserId = userId;
    _appointments = [];
    notifyListeners();
    if (userId == null) return;

    _sub = client
        .from('appointments')
        .stream(primaryKey: ['id'])
        .eq('student_id', userId)
        .order('created_at')
        .listen((rows) {
          _appointments = rows.map(Appointment.fromRow).toList();
          notifyListeners();
        }, onError: (Object e) => debugPrint('Appointment stream error: $e'));
  }

  /// Sends the request to the Guidance Office. Throws if it couldn't be
  /// saved, so the screen can tell the student.
  Future<void> requestAppointment({
    required AppointmentType type,
    required String subject,
    required DateTime preferredDate,
    String? description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please log in again.');

    final client = _client;
    if (client != null) {
      await client.from('appointments').insert({
        'student_id': user.id,
        'type': type.name,
        'subject': subject,
        'description': description,
        'preferred_at': preferredDate.toUtc().toIso8601String(),
      });
      // The live stream picks up the new row; counselors see it in their
      // inbox the same way.
      return;
    }

    _store?.addAppointment(
      Appointment(
        id: _store.newAppointmentId(),
        userId: user.id,
        type: type,
        subject: subject,
        preferredDate: preferredDate,
        createdAt: DateTime.now(),
        description: description,
      ),
    );
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _store?.removeListener(notifyListeners);
    _sub?.cancel();
    super.dispose();
  }
}
