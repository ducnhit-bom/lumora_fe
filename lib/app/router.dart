import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_placeholder_screen.dart';
import '../features/foundation/foundation_screen.dart';
import '../features/shell/lumora_shell.dart';

GoRouter createAppRouter({String initialLocation = '/today'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthPlaceholderScreen(),
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
              builder: (context, state) => const FoundationScreen(
                title: 'Today',
                headline: 'Plan a meaningful week, then return to one calm focus at a time.',
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/journey',
              builder: (context, state) => const FoundationScreen(
                title: 'Weekly Journey',
                headline: 'Mock mode keeps planning available while the API catches up.',
              ),
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
              builder: (context, state) => const FoundationScreen(
                title: 'Settings',
                headline: 'Preferences and logout will stay simple for MVP.',
              ),
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
