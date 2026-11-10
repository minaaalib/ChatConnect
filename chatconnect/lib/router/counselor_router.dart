import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../screens/chat/thread_chat_screen.dart';
import '../screens/counselor/counselor_chats_screen.dart';
import '../screens/counselor/counselor_inbox_screen.dart';
import '../screens/counselor/counselor_login_screen.dart';
import '../screens/counselor/counselor_shell.dart';
import '../screens/counselor/staff_id_screen.dart';
import '../services/auth_service.dart';
import '../services/counselor_service.dart';
import '../theme/app_theme.dart';

/// Routes for the Guidance Office web app (lib/main_counselor.dart).
GoRouter buildCounselorRouter(AuthService authService) {
  return GoRouter(
    initialLocation: '/counselor',
    refreshListenable: authService,
    redirect: (context, state) {
      final location = state.matchedLocation;
      // Step 2 of sign-in: password OK, staff school ID still needed.
      if (authService.awaitingStaffId) {
        return location == '/verify-id' ? null : '/verify-id';
      }
      if (authService.currentUser == null) {
        return location == '/login' ? null : '/login';
      }
      if (location == '/login' || location == '/verify-id') return '/counselor';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const CounselorLoginScreen(),
      ),
      GoRoute(
        path: '/verify-id',
        builder: (context, state) => const StaffIdScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => CounselorShell(child: child),
        routes: [
          GoRoute(
            path: '/counselor',
            builder: (context, state) => const CounselorInboxScreen(),
          ),
          GoRoute(
            path: '/counselor/chats',
            builder: (context, state) => const CounselorChatsScreen(),
          ),
          GoRoute(
            path: '/counselor/chats/:threadId',
            builder: (context, state) {
              final studentId = state.uri.queryParameters['student'];
              final service = context.read<CounselorService>();
              final student = studentId == null
                  ? null
                  : service.student(studentId);
              return ThreadChatScreen(
                threadId: state.pathParameters['threadId'],
                title: studentId == null
                    ? 'Student'
                    : service.studentName(studentId),
                subtitle: [
                  student?.studentId ?? '',
                  student?.course ?? '',
                ].where((s) => s.isNotEmpty).join(' · '),
                viewerIsCounselor: true,
                onBack: () => context.go('/counselor/chats'),
              );
            },
          ),
        ],
      ),
    ],
  );
}

/// Builds the router once and keeps it for the app's lifetime.
class CounselorRouterProvider extends StatefulWidget {
  const CounselorRouterProvider({super.key});

  @override
  State<CounselorRouterProvider> createState() =>
      _CounselorRouterProviderState();
}

class _CounselorRouterProviderState extends State<CounselorRouterProvider> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildCounselorRouter(context.read<AuthService>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'ChatConnect Guidance Office',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
    );
  }
}
