import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lumora_fe/app/app.dart';
import 'package:lumora_fe/features/auth/auth_controller.dart';
import 'package:lumora_fe/features/journey/journey_repository.dart';

class CurrentJourneyRepository implements JourneyRepository {
  @override
  Future<Journey?> currentJourney() async {
    return Journey(
      id: 'journey-current',
      weekStart: DateTime(2026, 6, 22),
      title: 'Existing week',
      status: 'draft',
      sessions: const [],
    );
  }

  @override
  Future<Journey> createJourney({
    required DateTime weekStart,
    required String title,
  }) async {
    return Journey(
      id: 'journey-new',
      weekStart: weekStart,
      title: title,
      status: 'draft',
      sessions: const [],
    );
  }

  @override
  Future<FocusSession> addSession({
    required String journeyId,
    required String title,
    required String category,
    required String priority,
    required int estimatedMinutes,
    String? note,
  }) async {
    return FocusSession(
      id: 'session-1',
      journeyId: journeyId,
      title: title,
      category: category,
      priority: priority,
      estimatedMinutes: estimatedMinutes,
      status: 'todo',
    );
  }

  @override
  Future<SuggestedJourney> suggest(String journeyId) async =>
      const SuggestedJourney(source: 'fallback', days: []);

  @override
  Future<AcceptedJourney> accept({
    required String journeyId,
    required SuggestedJourney suggestion,
  }) async {
    return const AcceptedJourney(
      id: 'journey-current',
      status: 'active',
      acceptedAt: '2026-06-22T09:00:00Z',
    );
  }
}

void main() {
  testWidgets('redirects unauthenticated users to auth', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LumoraApp()));

    expect(find.text('Welcome to Lumora'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('shows Lumora foundation shell tabs for authenticated user', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => AuthController.signedInForTest(),
          ),
        ],
        child: const LumoraApp(),
      ),
    );

    expect(find.text('Lumora'), findsOneWidget);
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Journey'), findsWidgets);
    expect(find.text('Review'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
    expect(
      find.text(
        'Plan a meaningful week, then return to one calm focus at a time.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('navigates between foundation tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => AuthController.signedInForTest(),
          ),
        ],
        child: const LumoraApp(),
      ),
    );

    await tester.tap(find.text('Journey').last);
    await tester.pumpAndSettle();

    expect(find.text('Weekly Journey'), findsOneWidget);
    expect(
      find.text('Design a gentle plan for the week ahead.'),
      findsOneWidget,
    );
    expect(find.text('Create journey'), findsOneWidget);
  });

  testWidgets('mock journey flow creates suggestion and accepts journey', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => AuthController.signedInForTest(),
          ),
        ],
        child: const LumoraApp(initialLocation: '/journey'),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('journey-title-field')),
      'A calm week',
    );
    await tester.tap(find.text('Create journey'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('session-title-field')),
      'Write proposal',
    );
    await tester.enterText(
      find.byKey(const Key('session-duration-field')),
      '45',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add focus'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create AI Journey'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept journey'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 900));
    await tester.pumpAndSettle();

    expect(
      find.text('Your weekly journey is ready for Today.'),
      findsOneWidget,
    );
  });

  testWidgets('journey screen loads current draft on open', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => AuthController.signedInForTest(),
          ),
          journeyRepositoryProvider.overrideWith(
            (ref) => CurrentJourneyRepository(),
          ),
        ],
        child: const LumoraApp(initialLocation: '/journey'),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Existing week'), findsOneWidget);
    expect(find.text('Create journey'), findsNothing);
  });

  testWidgets('shows auth placeholder route', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: LumoraApp(initialLocation: '/auth')),
    );

    expect(find.text('Welcome to Lumora'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('mock login enters Today and logout returns to auth', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: LumoraApp()));

    await tester.enterText(find.byType(EditableText).at(0), 'linh@example.com');
    await tester.enterText(find.byType(EditableText).at(1), 'secret123');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Lumora'), findsOneWidget);
  });
}
