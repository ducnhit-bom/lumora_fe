import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../journey/journey_repository.dart';
import 'review_repository.dart';

class ReviewState {
  const ReviewState({
    this.review,
    this.isLoading = false,
    this.hasNoJourney = false,
    this.errorMessage,
  });

  final WeeklyReview? review;
  final bool isLoading;
  final bool hasNoJourney;
  final String? errorMessage;
}

class ReviewController extends StateNotifier<ReviewState> {
  ReviewController(this._journeyRepository, this._reviewRepository)
    : super(const ReviewState());

  final JourneyRepository _journeyRepository;
  final ReviewRepository _reviewRepository;

  Future<void> load() async {
    state = const ReviewState(isLoading: true);
    try {
      final journey = await _journeyRepository.currentJourney();
      if (journey == null || journey.status != 'active') {
        state = const ReviewState(hasNoJourney: true);
        return;
      }
      final review = await _reviewRepository.review(journey.id);
      state = ReviewState(review: review);
    } catch (_) {
      state = const ReviewState(
        errorMessage: 'Weekly review could not be loaded. Please try again.',
      );
    }
  }
}

final reviewControllerProvider =
    StateNotifierProvider<ReviewController, ReviewState>((ref) {
      return ReviewController(
        ref.watch(journeyRepositoryProvider),
        ref.watch(reviewRepositoryProvider),
      );
    });
