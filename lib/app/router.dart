import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_placeholder_screen.dart';
import '../features/foundation/foundation_screen.dart';
import '../features/journey/journey_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/lumora_shell.dart';
import '../features/today/today_detail_screen.dart';
import '../features/today/today_screen.dart';

GoRouter createAppRouter({
  String initialLocation = '/today',
  bool isAuthenticated = false,
}) => GoRouter(
  initialLocation: initialLocation,
  redirect: (context, state) {
    final isAuthRoute = state.matchedLocation == '/auth';
    if (!isAuthenticated && !isAuthRoute) {
      return '/auth';
    }
    if (isAuthenticated && isAuthRoute) {
      return '/today';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthPlaceholderScreen(),
    ),
    GoRoute(
      path: '/sessions/:sessionId',
      builder: (context, state) =>
          TodayDetailScreen(sessionId: state.pathParameters['sessionId']!),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return LumoraShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/today',
              builder: (context, state) => const TodayScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/journey',
              builder: (context, state) => const JourneyScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/review',
              builder: (context, state) => const FoundationScreen(
                title: 'Review',
                headline: 'A gentle weekly reflection will live here.',
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => const Scaffold(
    body: Center(child: Text('This Lumora page is not available yet.')),
  ),
);

final appRouter = createAppRouter();
