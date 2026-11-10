import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

/// A meeting created for a confirmed appointment.
class MeetBooking {
  const MeetBooking({required this.meetLink, this.calendarEventLink});

  final String meetLink;
  final String? calendarEventLink;
}

/// Creates the Google Meet for an appointment when a counselor confirms it.
/// Used by the Guidance Office web app only — students never sign in to
/// Google; they get a Calendar invitation email and a Join button in the app.
abstract class MeetScheduler {
  /// True for the offline stand-in (no real meeting is created).
  bool get isDemo;

  Future<MeetBooking> createMeeting({
    required String title,
    String? description,
    required DateTime start,
    Duration duration = const Duration(minutes: 45),
    String? studentEmail,
  });
}

/// Real version: puts the event on the counselor's own Google Calendar with
/// a Meet link, and invites the student by email. Needs
/// GOOGLE_WEB_CLIENT_ID in .env (see docs/GOOGLE_MEET_SETUP.md).
class GoogleMeetScheduler implements MeetScheduler {
  GoogleMeetScheduler({required this.clientId});

  final String clientId;

  static const _scopes = <String>[
    'https://www.googleapis.com/auth/calendar.events',
  ];

  bool _initialized = false;

  @override
  bool get isDemo => false;

  /// Called once at app start, so the Google pop-up on the first Confirm
  /// click isn't blocked by the browser.
  Future<void> initialize() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(clientId: clientId);
    _initialized = true;
  }

  @override
  Future<MeetBooking> createMeeting({
    required String title,
    String? description,
    required DateTime start,
    Duration duration = const Duration(minutes: 45),
    String? studentEmail,
  }) async {
    await initialize();
    final auth = GoogleSignIn.instance.authorizationClient;
    final authorization =
        await auth.authorizationForScopes(_scopes) ??
        await auth.authorizeScopes(_scopes); // shows Google's pop-up
    final client = authorization.authClient(scopes: _scopes);
    try {
      final api = calendar.CalendarApi(client);
      final event = calendar.Event(
        summary: title,
        description: description,
        start: calendar.EventDateTime(dateTime: start, timeZone: 'Asia/Manila'),
        end: calendar.EventDateTime(
          dateTime: start.add(duration),
          timeZone: 'Asia/Manila',
        ),
        attendees: [
          // Skips sample addresses like name@demo, which Google rejects.
          if (studentEmail != null &&
              RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(studentEmail))
            calendar.EventAttendee(email: studentEmail),
        ],
        conferenceData: calendar.ConferenceData(
          createRequest: calendar.CreateConferenceRequest(
            requestId: 'chatconnect-${DateTime.now().microsecondsSinceEpoch}',
            conferenceSolutionKey: calendar.ConferenceSolutionKey(
              type: 'hangoutsMeet',
            ),
          ),
        ),
      );
      final created = await api.events.insert(
        event,
        'primary',
        conferenceDataVersion: 1,
        sendUpdates: 'all', // emails the invitation to the student
      );
      final meetLink = created.hangoutLink;
      if (meetLink == null) {
        throw Exception('Google Calendar did not return a Meet link.');
      }
      return MeetBooking(
        meetLink: meetLink,
        calendarEventLink: created.htmlLink,
      );
    } finally {
      client.close();
    }
  }
}

/// Offline demo: no Google account involved. The "meeting" link opens the
/// Google Meet home page so the Join buttons can be tried.
class DemoMeetScheduler implements MeetScheduler {
  static const demoMeetLink = 'https://meet.google.com/';

  @override
  bool get isDemo => true;

  @override
  Future<MeetBooking> createMeeting({
    required String title,
    String? description,
    required DateTime start,
    Duration duration = const Duration(minutes: 45),
    String? studentEmail,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const MeetBooking(meetLink: demoMeetLink);
  }
}
