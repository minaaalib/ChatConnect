import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'router/app_router.dart';
import 'services/appointment_service.dart';
import 'services/auth_service.dart';
import 'services/backend_config.dart';
import 'services/chat_repository.dart';
import 'services/counselor_chat_repository.dart';
import 'services/crisis_alert_reporter.dart';
import 'services/demo/demo_store.dart';
import 'services/insights_service.dart';
import 'services/journal_service.dart';
import 'services/home_widget_service.dart';
import 'services/live_chat_repository.dart';
import 'services/mock_auth_service.dart';
import 'services/mood_service.dart';
import 'services/supabase_auth_service.dart';
import 'models/user_profile.dart';

// Student app. Counselors use a separate app: lib/main_counselor.dart
// (Guidance Office web app). Both talk to the same Supabase project.
//
// Two modes, picked from .env:
// - SUPABASE_URL + SUPABASE_ANON_KEY set: real student accounts; crisis
//   alerts, appointment requests and Guidance Office chat reach the
//   counselor web app. Run supabase/migrations/*.sql in the project first.
// - Left empty: offline demo on MockAuthService with sample data. The demo
//   data lives inside this app only, so it doesn't reach the counselor app.
//
// Kai chat talks to kai-backend (FastAPI -> Google Gemini) via
// LiveChatRepository in both modes. Run kai-backend locally (see
// kai-backend/README.md) or chat falls back to "I'm having trouble
// connecting right now" for every message.
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
  await HomeWidgetService.initialize();
  runApp(
    ChatConnectApp(
      client: client,
      demoStore: client == null ? DemoStore() : null,
    ),
  );
}

class ChatConnectApp extends StatelessWidget {
  const ChatConnectApp({super.key, this.client, this.demoStore});

  /// Null in offline demo mode.
  final SupabaseClient? client;

  /// Sample data (appointments, alerts, Guidance Office chat); only used in
  /// offline demo mode.
  final DemoStore? demoStore;

  @override
  Widget build(BuildContext context) {
    final client = this.client;
    final store = demoStore ?? DemoStore();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => client != null
              ? SupabaseAuthService(client, appRole: UserRole.student)
              : MockAuthService(demoStore: store),
        ),
        // The real (or demo) Guidance Office chat replaces the old canned
        // counselor replies in both modes.
        Provider<ChatRepository>(
          create: (_) => LiveChatRepository(includeOfflineCounselor: false),
        ),
        ChangeNotifierProvider(create: (_) => MoodService()),
        ChangeNotifierProvider(create: (_) => InsightsService()),
        ChangeNotifierProvider(create: (_) => JournalService()),
        ChangeNotifierProvider(
          create: (context) => AppointmentService(
            client: client,
            demoStore: client == null ? store : null,
            auth: context.read<AuthService>(),
          ),
        ),
        Provider<CrisisAlertReporter>(
          create: (context) => client != null
              ? SupabaseCrisisAlertReporter(client)
              : DemoCrisisAlertReporter(store, context.read<AuthService>()),
        ),
        Provider<CounselorChatRepository>(
          create: (context) => client != null
              ? SupabaseCounselorChatRepository(client)
              : DemoCounselorChatRepository(store, context.read<AuthService>()),
        ),
      ],
      child: const AppRouterProvider(),
    );
  }
}
