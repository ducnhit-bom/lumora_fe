import 'package:flutter_test/flutter_test.dart';

import 'package:lumora_fe/features/today/today_controller.dart';
import 'package:lumora_fe/features/today/today_repository.dart';

class FakeTodayRepository implements TodayRepository {
  FakeTodayRepository({this.fail = false});

  bool fail;
  var session = const TodaySession(
    id: 'session-1',
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
  Future<TodayPlan> today() async {
    if (fail) throw Exception('network');
    return TodayPlan(date: '2026-06-29', sessions: [session]);
  }

  @override
  Future<TodaySession> detail(String sessionId) async {
    if (fail) throw Exception('network');
    return session;
  }

  @override
  Future<CompleteResult> complete(String sessionId) async {
    if (fail) throw Exception('network');
    if (session.status != 'scheduled') throw Exception('invalid state');
    session = session.copyWith(
      status: 'completed',
      completedAt: '2026-06-29T09:30:00Z',
    );
    return const CompleteResult(
      sessionId: 'session-1',
      status: 'completed',
      completedAt: '2026-06-29T09:30:00Z',
      openReflection: true,
    );
  }

  @override
  Future<UndoCompleteResult> undoComplete(String sessionId) async {
    if (fail) throw Exception('network');
    session = session.copyWith(status: 'scheduled', clearCompletedAt: true);
    return const UndoCompleteResult(
      sessionId: 'session-1',
      status: 'scheduled',
    );
  }

  @override
  Future<SkipResult> skip(String sessionId) async {
    if (fail) throw Exception('network');
    session = session.copyWith(
      status: 'skipped',
      skippedAt: '2026-06-29T09:45:00Z',
    );
    return const SkipResult(
      sessionId: 'session-1',
      status: 'skipped',
      skippedAt: '2026-06-29T09:45:00Z',
    );
  }
}

void main() {
  test('loads today sessions', () async {
    final controller = TodayController(FakeTodayRepository());

    await controller.loadToday();

    expect(controller.state.plan?.sessions.single.title, 'Write proposal');
    expect(controller.state.errorMessage, isNull);
  });

  test('complete updates session and requests reflection', () async {
    final controller = TodayController(FakeTodayRepository());

    await controller.loadToday();
    await controller.complete('session-1');

    expect(controller.state.plan?.sessions.single.status, 'completed');
    expect(controller.state.openReflectionSessionId, 'session-1');
  });

  test('undo complete returns session to scheduled', () async {
    final controller = TodayController(FakeTodayRepository());

    await controller.loadToday();
    await controller.complete('session-1');
    await controller.undoComplete('session-1');

    expect(controller.state.plan?.sessions.single.status, 'scheduled');
    expect(controller.state.openReflectionSessionId, isNull);
  });

  test('skip marks session skipped', () async {
    final controller = TodayController(FakeTodayRepository());

    await controller.loadToday();
    await controller.skip('session-1');

    expect(controller.state.plan?.sessions.single.status, 'skipped');
  });

  test('repository failure leaves retryable error state', () async {
    final controller = TodayController(FakeTodayRepository(fail: true));

    await controller.loadToday();

    expect(controller.state.isLoading, isFalse);
    expect(
      controller.state.errorMessage,
      'Today could not be updated. Please try again.',
    );
  });
}
