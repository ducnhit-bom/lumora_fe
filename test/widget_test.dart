import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lumora_fe/app/app.dart';
import 'package:lumora_fe/features/auth/auth_controller.dart';
import 'package:lumora_fe/features/journey/journey_repository.dart';
import 'package:lumora_fe/features/reflection/reflection_repository.dart';
import 'package:lumora_fe/features/today/today_repository.dart';

class ScheduledTodayRepository implements TodayRepository {
  var session = const TodaySession(
    id: 'today-1',
    journeyId: 'journey-1',
    title: 'Write proposal',
    category: 'work',
    priority: 'high',
    estimatedMinutes: 45,
    scheduledDate: '2026-06-29',
    scheduledTime: '09:00',
    status: 'scheduled',
  );

  @override
  Future<TodayPlan> today() async =>
      TodayPlan(date: '2026-06-29', sessions: [session]);

  @override
  Future<TodaySession> detail(String sessionId) async => session;

  @override
  Future<CompleteResult> complete(String sessionId) async {
    session = session.copyWith(
      status: 'completed',
      completedAt: '2026-06-29T09:30:00Z',
    );
    return const CompleteResult(
      sessionId: 'today-1',
      status: 'completed',
      completedAt: '2026-06-29T09:30:00Z',
      openReflection: true,
    );
  }

  @override
  Future<UndoCompleteResult> undoComplete(String sessionId) async {
    session = session.copyWith(status: 'scheduled', clearCompletedAt: true);
    return const UndoCompleteResult(sessionId: 'today-1', status: 'scheduled');
  }

  @override
  Future<SkipResult> skip(String sessionId) async {
    session = session.copyWith(
      status: 'skipped',
      skippedAt: '2026-06-29T09:45:00Z',
    );
    return const SkipResult(
      sessionId: 'today-1',
      status: 'skipped',
      skippedAt: '2026-06-29T09:45:00Z',
    );
  }
}

class EmptyTodayRepository extends ScheduledTodayRepository {
  @override
  Future<TodayPlan> today() async =>
      const TodayPlan(date: '2026-06-29', sessions: []);
}

class FakeReflectionRepository implements ReflectionRepository {
  int saveCount = 0;

  @override
  Future<ReflectionQuestion> question(String sessionId) async {
    return ReflectionQuestion(
      sessionId: sessionId,
      question: 'What helped you make progress?',
    );
  }

  @override
  Future<Reflection> save({
    required String sessionId,
    required String content,
    String? mood,
  }) async {
    saveCount += 1;
    return Reflection(
      id: 'reflection-$saveCount',
      journeyId: 'journey-1',
      sessionId: sessionId,
      content: content,
      mood: mood,
      createdAt: '2026-06-29T09:30:00Z',
    );
  }
}

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
    expect(find.text('Today'), findsWidgets);
    expect(find.text('One calm focus at a time.'), findsOneWidget);
  });

  testWidgets('today screen opens reflection after completion', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => AuthController.signedInForTest(),
          ),
          todayRepositoryProvider.overrideWith(
            (ref) => ScheduledTodayRepository(),
          ),
          reflectionRepositoryProvider.overrideWith(
            (ref) => FakeReflectionRepository(),
          ),
        ],
        child: const LumoraApp(initialLocation: '/today'),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Write proposal'), findsWidgets);
    expect(find.text('09:00 • 45 min • high'), findsWidgets);

    await tester.tap(find.text('Complete'));
    await tester.pumpAndSettle();

    expect(find.text('Reflection'), findsOneWidget);
    expect(find.text('What helped you make progress?'), findsOneWidget);
  });

  testWidgets('reflection route saves and returns to Today', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => AuthController.signedInForTest(),
          ),
          todayRepositoryProvider.overrideWith(
            (ref) => ScheduledTodayRepository(),
          ),
          reflectionRepositoryProvider.overrideWith(
            (ref) => FakeReflectionRepository(),
          ),
        ],
        child: const LumoraApp(
          initialLocation: '/reflections/session/today-1',
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('reflection-content-field')),
      'I found one calm next step.',
    );
    await tester.tap(find.text('Balanced'));
    await tester.tap(find.text('Save reflection'));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('One calm focus at a time.'), findsOneWidget);
  });

  testWidgets('reflection route skips without saving and returns to Today', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => AuthController.signedInForTest(),
          ),
          todayRepositoryProvider.overrideWith(
            (ref) => ScheduledTodayRepository(),
          ),
          reflectionRepositoryProvider.overrideWith(
            (ref) => FakeReflectionRepository(),
          ),
        ],
        child: const LumoraApp(
          initialLocation: '/reflections/session/today-1',
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip reflection'));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('One calm focus at a time.'), findsOneWidget);
  });

  testWidgets('reflection route can reopen after a previous skip', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => AuthController.signedInForTest(),
          ),
          todayRepositoryProvider.overrideWith(
            (ref) => ScheduledTodayRepository(),
          ),
          reflectionRepositoryProvider.overrideWith(
            (ref) => FakeReflectionRepository(),
          ),
        ],
        child: const LumoraApp(
          initialLocation: '/reflections/session/today-1',
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip reflection'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Complete'));
    await tester.pumpAndSettle();

    expect(find.text('Reflection'), findsOneWidget);
    expect(find.text('What helped you make progress?'), findsOneWidget);
  });

  testWidgets('today session detail route shows focused detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => AuthController.signedInForTest(),
          ),
          todayRepositoryProvider.overrideWith(
            (ref) => ScheduledTodayRepository(),
          ),
        ],
        child: const LumoraApp(initialLocation: '/sessions/today-1'),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Focus detail'), findsOneWidget);
    expect(find.text('Write proposal'), findsWidgets);
    expect(find.text('Complete'), findsOneWidget);
  });

  testWidgets('today screen shows friendly empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => AuthController.signedInForTest(),
          ),
          todayRepositoryProvider.overrideWith((ref) => EmptyTodayRepository()),
        ],
        child: const LumoraApp(initialLocation: '/today'),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No focus sessions today.'), findsOneWidget);
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
