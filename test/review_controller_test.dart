import 'package:flutter_test/flutter_test.dart';

import 'package:lumora_fe/features/journey/journey_repository.dart';
import 'package:lumora_fe/features/review/review_controller.dart';
import 'package:lumora_fe/features/review/review_repository.dart';

class FakeJourneyRepository implements JourneyRepository {
  FakeJourneyRepository({this.journey, this.fail = false});

  Journey? journey;
  bool fail;

  @override
  Future<Journey?> currentJourney() async {
    if (fail) throw Exception('network');
    return journey;
  }

  @override
  Future<Journey> createJourney({required DateTime weekStart, required String title}) async => throw UnimplementedError();

  @override
  Future<FocusSession> addSession({
    required String journeyId,
    required String title,
    required String category,
    required String priority,
    required int estimatedMinutes,
    String? note,
  }) async => throw UnimplementedError();

  @override
  Future<SuggestedJourney> suggest(String journeyId) async => throw UnimplementedError();

  @override
  Future<AcceptedJourney> accept({required String journeyId, required SuggestedJourney suggestion}) async => throw UnimplementedError();
}

class FakeReviewRepository implements ReviewRepository {
  FakeReviewRepository({this.fail = false});

  bool fail;

  @override
  Future<WeeklyReview> review(String journeyId) async {
    if (fail) throw Exception('network');
    return const WeeklyReview(
      journeyId: 'journey-1',
      sessionsCompleted: 2,
      reflectionCount: 1,
      moodSummary: MoodSummary(energized: 0, balanced: 1, challenged: 0),
      insight: ReviewInsight(source: 'fallback', text: 'You made steady progress.'),
      recommendation: 'Plan next week with more breathing room.',
    );
  }
}

Journey _journey() => Journey(
  id: 'journey-1',
  weekStart: DateTime(2026, 6, 29),
  title: 'A calm week',
  status: 'active',
  sessions: const [],
);

Journey _draftJourney() => Journey(
  id: 'journey-draft',
  weekStart: DateTime(2026, 6, 29),
  title: 'Draft week',
  status: 'draft',
  sessions: const [],
);

void main() {
  test('no current journey becomes empty review state', () async {
    final controller = ReviewController(FakeJourneyRepository(), FakeReviewRepository());

    await controller.load();

    expect(controller.state.hasNoJourney, isTrue);
    expect(controller.state.review, isNull);
    expect(controller.state.errorMessage, isNull);
  });

  test('draft current journey becomes empty review state', () async {
    final controller = ReviewController(FakeJourneyRepository(journey: _draftJourney()), FakeReviewRepository());

    await controller.load();

    expect(controller.state.hasNoJourney, isTrue);
    expect(controller.state.review, isNull);
  });

  test('loads review for current journey', () async {
    final controller = ReviewController(FakeJourneyRepository(journey: _journey()), FakeReviewRepository());

    await controller.load();

    expect(controller.state.hasNoJourney, isFalse);
    expect(controller.state.review?.sessionsCompleted, 2);
    expect(controller.state.review?.moodSummary.balanced, 1);
  });

  test('repository failure leaves friendly error', () async {
    final controller = ReviewController(FakeJourneyRepository(journey: _journey()), FakeReviewRepository(fail: true));

    await controller.load();

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.errorMessage, 'Weekly review could not be loaded. Please try again.');
  });
}
