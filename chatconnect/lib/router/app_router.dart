import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';

import '../screens/appointment/appointment_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/insights/insights_screen.dart';
import '../screens/journal/journal_screen.dart';
import '../screens/chat/messages_screen.dart';
import '../screens/chat/thread_chat_screen.dart';
import '../services/counselor_chat_repository.dart';
import '../screens/kai_hub/kai_hub_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/shell/app_shell.dart';
import '../screens/sos/sos_screen.dart';
import '../services/auth_service.dart';
import '../services/home_widget_service.dart';
import '../theme/app_theme.dart';

/// Id of the student's counselor chat in the Messages list.
const counselorSessionId = 'session-counselor-1';

GoRouter buildAppRouter(AuthService authService) {
  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: authService,
    redirect: (context, state) {
      final user = authService.currentUser;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/onboarding' || location == '/login';

      if (user == null) return isAuthRoute ? null : '/onboarding';
      if (isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: '/chat/:sessionId',
            builder: (context, state) {
              final sessionId = state.pathParameters['sessionId']!;
              // With Supabase on, the counselor session is the real
              // Guidance Office thread instead of the offline stand-in.
              final hasCounselorChat =
                  context.read<CounselorChatRepository?>() != null;
              final me = context.read<AuthService>().currentUser;
              if (sessionId == counselorSessionId &&
                  hasCounselorChat &&
                  me != null) {
                return ThreadChatScreen(
                  studentId: me.id,
                  title: 'WVSU Guidance Office',
                  subtitle: 'Counselors reply during office hours',
                  onBack: () => context.go('/chat'),
                );
              }
              return ChatScreen(sessionId: sessionId);
            },
          ),
          GoRoute(
            path: '/insights',
            builder: (context, state) => const InsightsScreen(),
          ),
          GoRoute(
            path: '/kai-hub',
            builder: (context, state) => const KaiHubScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/journal',
        builder: (context, state) => const JournalScreen(),
      ),
      GoRoute(
        path: '/appointment',
        builder: (context, state) => const AppointmentScreen(),
      ),
      GoRoute(path: '/sos', builder: (context, state) => const SosScreen()),
    ],
  );
}

/// Builds the router once and keeps it alive for the app's lifetime,
/// reading the AuthService from Provider so `redirect` reacts to sign-in state.
class AppRouterProvider extends StatefulWidget {
  const AppRouterProvider({super.key});

  @override
  State<AppRouterProvider> createState() => _AppRouterProviderState();
}

class _AppRouterProviderState extends State<AppRouterProvider> {
  late final GoRouter _router;
  StreamSubscription<Uri?>? _widgetClickSubscription;

  @override
  void initState() {
    super.initState();
    _router = buildAppRouter(context.read<AuthService>());
    HomeWidgetService.pushQuoteOfTheDay();
    _handleHomeWidgetLaunch();
  }

  /// Routes the app to `/sos` when launched from the widget's SOS button —
  /// both the cold-start case (app wasn't running) and the warm case (app
  /// was already running in the background).
  Future<void> _handleHomeWidgetLaunch() async {
    if (kIsWeb) return;
    final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    _routeIfSosLaunch(initialUri);
    _widgetClickSubscription = HomeWidget.widgetClicked.listen(
      _routeIfSosLaunch,
    );
  }

  void _routeIfSosLaunch(Uri? uri) {
    if (HomeWidgetService.isSosLaunch(uri)) _router.go('/sos');
  }

  @override
  void dispose() {
    _widgetClickSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'ChatConnect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
    );
  }
}
