import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/appointment.dart';
import '../../models/counselor_thread.dart';
import '../../models/crisis_alert.dart';
import '../../models/user_profile.dart';
import '../auth_service.dart';
import '../counselor_chat_repository.dart';
import '../counselor_service.dart';
import '../crisis_alert_reporter.dart';

/// Offline demo data for the counselor side, kept in memory while the app
/// runs (used when Supabase isn't configured). Lets you show the full flow
/// on one device: log in as a student, book / trigger an alert, log out,
/// log in as `counselor@demo`, and handle it.
///
/// All sample students and messages are fictional.
class DemoStore extends ChangeNotifier {
  DemoStore() {
    _seed();
  }

  static const counselorId = 'demo-counselor';

  final profiles = <String, UserProfile>{};
  final alerts = <CrisisAlert>[];
  final appointments = <Appointment>[];
  final threads = <CounselorThread>[];
  final _messages = <String, List<ThreadMessage>>{};

  final _changes = StreamController<void>.broadcast();
  int _nextId = 1;

  String _id(String prefix) => '$prefix-${_nextId++}';

  UserProfile get counselor => profiles[counselorId]!;

  void _changed() {
    notifyListeners();
    _changes.add(null);
  }

  void upsertProfile(UserProfile p) {
    profiles[p.id] = p;
    _changed();
  }

  // ------------------------------------------------------------- alerts
  void addAlert(String studentId, CrisisSource source, String excerpt) {
    alerts.insert(
      0,
      CrisisAlert(
        id: _id('alert'),
        studentId: studentId,
        source: source,
        status: CrisisAlertStatus.newAlert,
        createdAt: DateTime.now(),
        excerpt: excerpt,
      ),
    );
    _changed();
  }

  void updateAlert(String id, CrisisAlertStatus status, String? note) {
    final i = alerts.indexWhere((a) => a.id == id);
    if (i == -1) return;
    final a = alerts[i];
    alerts[i] = CrisisAlert(
      id: a.id,
      studentId: a.studentId,
      source: a.source,
      status: status,
      createdAt: a.createdAt,
      excerpt: a.excerpt,
      counselorNote: (note != null && note.trim().isNotEmpty)
          ? note.trim()
          : a.counselorNote,
    );
    _changed();
  }

  // ------------------------------------------------------- appointments
  void addAppointment(Appointment a) {
    appointments.insert(0, a);
    _changed();
  }

  String newAppointmentId() => _id('appt');

  void decideAppointment(
    String id,
    AppointmentStatus status,
    String? note, {
    String? meetLink,
    String? calendarEventLink,
  }) {
    final i = appointments.indexWhere((a) => a.id == id);
    if (i == -1) return;
    appointments[i] = appointments[i].copyWith(
      status: status,
      counselorNote: (note != null && note.trim().isNotEmpty)
          ? note.trim()
          : null,
      meetLink: meetLink,
      calendarEventLink: calendarEventLink,
    );
    _changed();
  }

  // --------------------------------------------------------------- chat
  String threadIdForStudent(String studentId) {
    for (final t in threads) {
      if (t.studentId == studentId) return t.id;
    }
    final t = CounselorThread(
      id: _id('thread'),
      studentId: studentId,
      lastMessageAt: DateTime.now(),
    );
    threads.insert(0, t);
    _messages[t.id] = [];
    _changed();
    return t.id;
  }

  List<ThreadMessage> messagesIn(String threadId) =>
      List.unmodifiable(_messages[threadId] ?? const []);

  Stream<List<ThreadMessage>> watchMessages(String threadId) async* {
    yield messagesIn(threadId);
    await for (final _ in _changes.stream) {
      yield messagesIn(threadId);
    }
  }

  void send(String threadId, String senderId, String body, {DateTime? at}) {
    final now = at ?? DateTime.now();
    (_messages[threadId] ??= []).add(
      ThreadMessage(
        id: _id('msg'),
        threadId: threadId,
        senderId: senderId,
        body: body,
        createdAt: now,
      ),
    );
    final i = threads.indexWhere((t) => t.id == threadId);
    if (i != -1) {
      final t = threads.removeAt(i);
      threads.insert(
        0,
        CounselorThread(
          id: t.id,
          studentId: t.studentId,
          lastMessageAt: now,
          lastMessagePreview: body.length > 140 ? body.substring(0, 140) : body,
          lastSenderId: senderId,
        ),
      );
    }
    _changed();
  }

  // --------------------------------------------------------------- seed
  void _seed() {
    final now = DateTime.now();
    DateTime ago(Duration d) => now.subtract(d);
    DateTime at(int days, int hour) =>
        DateTime(now.year, now.month, now.day + days, hour);

    for (final p in const [
      UserProfile(
        id: counselorId,
        fullName: 'Ms. Aurine',
        studentId: '',
        course: 'WVSU Guidance Office',
        email: 'counselor@demo',
        role: UserRole.counselor,
      ),
      UserProfile(
        id: 'demo-s1',
        fullName: 'Maria Santos',
        studentId: '2023-10418',
        course: 'BSEd English',
        email: 'maria.santos@demo',
      ),
      UserProfile(
        id: 'demo-s2',
        fullName: 'Juan Dela Cruz',
        studentId: '2022-08731',
        course: 'BS Information Technology',
        email: 'juan.delacruz@demo',
      ),
      UserProfile(
        id: 'demo-s3',
        fullName: 'Ana Reyes',
        studentId: '2024-02265',
        course: 'BS Psychology',
        email: 'ana.reyes@demo',
      ),
    ]) {
      profiles[p.id] = p;
    }

    alerts.addAll([
      CrisisAlert(
        id: _id('alert'),
        studentId: 'demo-s1',
        source: CrisisSource.keyword,
        status: CrisisAlertStatus.newAlert,
        createdAt: ago(const Duration(minutes: 12)),
        excerpt:
            "I don't see the point of anything anymore. I don't want to be "
            'here.',
      ),
      CrisisAlert(
        id: _id('alert'),
        studentId: 'demo-s2',
        source: CrisisSource.ai,
        status: CrisisAlertStatus.acknowledged,
        createdAt: ago(const Duration(hours: 3)),
        excerpt:
            "Everything is piling up and I haven't slept properly in days. "
            'I feel like I am drowning.',
      ),
    ]);

    appointments.addAll([
      Appointment(
        id: _id('appt'),
        userId: 'demo-s1',
        type: AppointmentType.crisis,
        subject: 'I need to talk to someone soon',
        preferredDate: at(0, 15),
        createdAt: ago(const Duration(minutes: 10)),
      ),
      Appointment(
        id: _id('appt'),
        userId: 'demo-s3',
        type: AppointmentType.personal,
        subject: 'Feeling overwhelmed with family issues',
        description:
            'Things at home have been hard and it is affecting my classes.',
        preferredDate: at(1, 10),
        createdAt: ago(const Duration(hours: 5)),
      ),
      Appointment(
        id: _id('appt'),
        userId: 'demo-s2',
        type: AppointmentType.academic,
        subject: 'Thesis stress and time management',
        preferredDate: at(2, 14),
        createdAt: ago(const Duration(days: 1)),
      ),
    ]);

    final t2 = threadIdForStudent('demo-s2');
    send(
      t2,
      counselorId,
      "Hi Juan, it's Ms. Aurine from the Guidance Office. I saw you've been "
      'having a rough week. How are you holding up today?',
      at: ago(const Duration(hours: 2, minutes: 40)),
    );
    send(
      t2,
      'demo-s2',
      'Hi po. A bit better today, but I still cannot sleep well. Can we talk '
          'this week?',
      at: ago(const Duration(hours: 2)),
    );
  }

  @override
  void dispose() {
    _changes.close();
    super.dispose();
  }
}

class DemoCounselorService extends CounselorService {
  DemoCounselorService(this._store) {
    _store.addListener(notifyListeners);
  }

  final DemoStore _store;

  @override
  List<CrisisAlert> get alerts => _store.alerts;
  @override
  List<Appointment> get appointments => _store.appointments;
  @override
  List<CounselorThread> get threads => _store.threads;
  @override
  UserProfile? student(String id) => _store.profiles[id];

  @override
  Future<void> updateAlert(
    String alertId,
    CrisisAlertStatus status, {
    String? note,
  }) async => _store.updateAlert(alertId, status, note);

  @override
  Future<void> decideAppointment(
    String appointmentId,
    AppointmentStatus status, {
    String? note,
    String? meetLink,
    String? calendarEventLink,
  }) async => _store.decideAppointment(
    appointmentId,
    status,
    note,
    meetLink: meetLink,
    calendarEventLink: calendarEventLink,
  );

  @override
  void dispose() {
    _store.removeListener(notifyListeners);
    super.dispose();
  }
}

class DemoCounselorChatRepository implements CounselorChatRepository {
  DemoCounselorChatRepository(this._store, this._auth);

  final DemoStore _store;
  final AuthService _auth;

  @override
  String? get currentUserId => _auth.currentUser?.id;

  @override
  Future<String> threadIdForStudent(String studentId) async =>
      _store.threadIdForStudent(studentId);

  @override
  Stream<List<ThreadMessage>> messages(String threadId) =>
      _store.watchMessages(threadId);

  @override
  Future<void> send({required String threadId, required String body}) async {
    final me = currentUserId;
    if (me == null) throw Exception('Please log in again.');
    _store.send(threadId, me, body);
  }
}

class DemoCrisisAlertReporter extends CrisisAlertReporter {
  DemoCrisisAlertReporter(this._store, this._auth);

  final DemoStore _store;
  final AuthService _auth;

  @override
  Future<void> save({
    required CrisisSource source,
    required String excerpt,
  }) async {
    final me = _auth.currentUser;
    if (me == null) return;
    _store.addAlert(me.id, source, excerpt);
  }
}
