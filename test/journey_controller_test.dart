import 'package:flutter_test/flutter_test.dart';

import 'package:lumora_fe/features/journey/journey_controller.dart';
import 'package:lumora_fe/features/journey/journey_repository.dart';

class FakeJourneyRepository implements JourneyRepository {
  bool fail = false;
  bool addCalled = false;

  @override
  Future<Journey> createJourney({
    required DateTime weekStart,
    required String title,
  }) async {
    if (fail) throw Exception('network');
    return Journey(
      id: 'journey-1',
      weekStart: weekStart,
      title: title,
      status: 'draft',
      sessions: const [],
    );
  }

  @override
  Future<Journey?> currentJourney() async => null;

  @override
  Future<FocusSession> addSession({
    required String journeyId,
    required String title,
    required String category,
    required String priority,
    required int estimatedMinutes,
    String? note,
  }) async {
    addCalled = true;
    if (fail) throw Exception('network');
    return FocusSession(
      id: 'session-1',
      journeyId: journeyId,
      title: title,
      note: note,
      category: category,
      priority: priority,
      estimatedMinutes: estimatedMinutes,
      status: 'todo',
    );
  }

  @override
  Future<SuggestedJourney> suggest(String journeyId) async {
    if (fail) throw Exception('network');
    return const SuggestedJourney(
      source: 'fallback',
      days: [
        SuggestedDay(
          date: '2026-06-29',
          sessions: [
            SuggestedSession(
              sessionId: 'session-1',
              suggestedTime: '09:00',
              reason: 'Start fresh.',
            ),
          ],
        ),
      ],
    );
  }

  @override
  Future<AcceptedJourney> accept({
    required String journeyId,
    required SuggestedJourney suggestion,
  }) async {
    if (fail) throw Exception('network');
    return const AcceptedJourney(
      id: 'journey-1',
      status: 'active',
      acceptedAt: '2026-06-29T09:00:00Z',
    );
  }
}

void main() {
  test('creates draft and adds a focus session', () async {
    final repository = FakeJourneyRepository();
    final controller = JourneyController(repository);

    await controller.createDraft(title: 'A calm week');
    await controller.addSession(
      title: 'Write proposal',
      category: 'work',
      priority: 'high',
      estimatedMinutes: 45,
    );

    expect(controller.state.journey?.title, 'A calm week');
    expect(controller.state.journey?.sessions.single.title, 'Write proposal');
    expect(controller.state.errorMessage, isNull);
  });

  test('blank session title is rejected without calling repository', () async {
    final repository = FakeJourneyRepository();
    final controller = JourneyController(repository);

    await controller.createDraft(title: 'A calm week');
    await controller.addSession(
      title: '   ',
      category: 'work',
      priority: 'high',
      estimatedMinutes: 45,
    );

    expect(repository.addCalled, isFalse);
    expect(
      controller.state.errorMessage,
      'Add a title and duration for this focus session.',
    );
  });

  test('suggest preview and accept mark journey active', () async {
    final controller = JourneyController(FakeJourneyRepository());

    await controller.createDraft(title: 'A calm week');
    await controller.addSession(
      title: 'Write proposal',
      category: 'work',
      priority: 'high',
      estimatedMinutes: 45,
    );
    await controller.suggest();
    await controller.acceptSuggestion();

    expect(controller.state.suggestion?.source, 'fallback');
    expect(controller.state.journey?.status, 'active');
    expect(
      controller.state.acceptedMessage,
      'Your weekly journey is ready for Today.',
    );
  });

  test('repository failure leaves retryable error state', () async {
    final repository = FakeJourneyRepository()..fail = true;
    final controller = JourneyController(repository);

    await controller.createDraft(title: 'A calm week');

    expect(controller.state.isLoading, isFalse);
    expect(
      controller.state.errorMessage,
      'Journey could not be updated. Please try again.',
    );
  });
}
