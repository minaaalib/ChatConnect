import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/user_profile.dart';
import 'router/counselor_router.dart';
import 'services/auth_service.dart';
import 'services/backend_config.dart';
import 'services/counselor_chat_repository.dart';
import 'services/counselor_service.dart';
import 'services/demo/demo_store.dart';
import 'services/meet_scheduler.dart';
import 'services/mock_auth_service.dart';
import 'services/supabase_auth_service.dart';

// ChatConnect Guidance Office: the counselor-only web app.
// The student app is lib/main.dart; both use the same Supabase project.
//
//   Run:   flutter run -d chrome -t lib/main_counselor.dart
//   Build: flutter build web -t lib/main_counselor.dart -o build/web_counselor
//
// Confirming an appointment creates a Google Meet on the counselor's Google
// Calendar and invites the student (GOOGLE_WEB_CLIENT_ID in .env; see
// docs/GOOGLE_MEET_SETUP.md). Without it, a demo Meet link is used.
//
// Only counselor accounts can sign in here (student accounts are refused).
// With SUPABASE_URL/SUPABASE_ANON_KEY empty in .env it runs as an offline
// demo: any email/password signs in as the sample counselor, with sample
// students, alerts and appointments from DemoStore.
Future<void> main() async {
  await dotenv.load(fileName: '.env');
  SupabaseClient? client;
  if (BackendConfig.supabaseEnabled) {
    await Supabase.initialize(
      url: BackendConfig.supabaseUrl,
      publishableKey: BackendConfig.supabaseAnonKey,
    );
    client = Supabase.instance.client;
  }
  final googleClientId = BackendConfig.googleWebClientId;
  final MeetScheduler meetScheduler;
  if (googleClientId.isNotEmpty) {
    final google = GoogleMeetScheduler(clientId: googleClientId);
    await google.initialize();
    meetScheduler = google;
  } else {
    meetScheduler = DemoMeetScheduler();
  }
  runApp(CounselorApp(client: client, meetScheduler: meetScheduler));
}

class CounselorApp extends StatelessWidget {
  const CounselorApp({super.key, this.client, this.meetScheduler});

  /// Null in offline demo mode.
  final SupabaseClient? client;

  /// Creates the Google Meet when an appointment is confirmed. Defaults to
  /// demo links.
  final MeetScheduler? meetScheduler;

  @override
  Widget build(BuildContext context) {
    final client = this.client;
    final store = client == null ? DemoStore() : null;
    return MultiProvider(
      providers: [
        Provider<MeetScheduler>.value(
          value: meetScheduler ?? DemoMeetScheduler(),
        ),
        ChangeNotifierProvider<AuthService>(
          create: (_) => client != null
              ? SupabaseAuthService(client, appRole: UserRole.counselor)
              : MockAuthService(demoStore: store, appRole: UserRole.counselor),
        ),
        Provider<CounselorChatRepository>(
          create: (context) => client != null
              ? SupabaseCounselorChatRepository(client)
              : DemoCounselorChatRepository(
                  store!,
                  context.read<AuthService>(),
                ),
        ),
        ChangeNotifierProvider<CounselorService>(
          create: (context) => client != null
              ? SupabaseCounselorService(client, context.read<AuthService>())
              : DemoCounselorService(store!),
        ),
      ],
      child: const CounselorRouterProvider(),
    );
  }
}
