import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_environment.dart';
import '../../core/network/dio_provider.dart';

class MoodSummary {
  const MoodSummary({
    required this.energized,
    required this.balanced,
    required this.challenged,
  });

  final int energized;
  final int balanced;
  final int challenged;

  String get strongest {
    if (energized >= balanced && energized >= challenged && energized > 0) {
      return 'Energized';
    }
    if (challenged > energized && challenged > balanced) {
      return 'Challenged';
    }
    if (balanced > 0) return 'Balanced';
    return 'Not enough data';
  }
}

class ReviewInsight {
  const ReviewInsight({required this.source, required this.text});

  final String source;
  final String text;
}

class WeeklyReview {
  const WeeklyReview({
    required this.journeyId,
    required this.sessionsCompleted,
    required this.reflectionCount,
    required this.moodSummary,
    required this.insight,
    required this.recommendation,
  });

  final String journeyId;
  final int sessionsCompleted;
  final int reflectionCount;
  final MoodSummary moodSummary;
  final ReviewInsight insight;
  final String recommendation;
}

abstract class ReviewRepository {
  Future<WeeklyReview> review(String journeyId);
}

class MockReviewRepository implements ReviewRepository {
  @override
  Future<WeeklyReview> review(String journeyId) async {
    return WeeklyReview(
      journeyId: journeyId,
      sessionsCompleted: 2,
      reflectionCount: 1,
      moodSummary: const MoodSummary(
        energized: 0,
        balanced: 1,
        challenged: 0,
      ),
      insight: const ReviewInsight(
        source: 'fallback',
        text: 'You made steady progress by protecting small focus windows.',
      ),
      recommendation:
          'Plan next week with one clear high-priority focus and a little more breathing room.',
    );
  }
}

class ApiReviewRepository implements ReviewRepository {
  ApiReviewRepository(this._dio);

  final Dio _dio;

  @override
  Future<WeeklyReview> review(String journeyId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/journeys/$journeyId/review',
    );
    return _review(response.data!);
  }
}

WeeklyReview _review(Map<String, dynamic> data) {
  final mood = data['moodSummary'] as Map<String, dynamic>;
  final insight = data['insight'] as Map<String, dynamic>;
  return WeeklyReview(
    journeyId: data['journeyId'] as String,
    sessionsCompleted: data['sessionsCompleted'] as int,
    reflectionCount: data['reflectionCount'] as int,
    moodSummary: MoodSummary(
      energized: mood['energized'] as int,
      balanced: mood['balanced'] as int,
      challenged: mood['challenged'] as int,
    ),
    insight: ReviewInsight(
      source: insight['source'] as String,
      text: insight['text'] as String,
    ),
    recommendation: data['recommendation'] as String,
  );
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockReviewRepository();
  }
  return ApiReviewRepository(ref.watch(dioProvider));
});
