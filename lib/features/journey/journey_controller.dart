import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'journey_repository.dart';

class JourneyState {
  const JourneyState({
    this.journey,
    this.suggestion,
    this.isLoading = false,
    this.errorMessage,
    this.acceptedMessage,
  });

  final Journey? journey;
  final SuggestedJourney? suggestion;
  final bool isLoading;
  final String? errorMessage;
  final String? acceptedMessage;

  JourneyState copyWith({
    Journey? journey,
    SuggestedJourney? suggestion,
    bool? isLoading,
    String? errorMessage,
    String? acceptedMessage,
    bool clearError = false,
    bool clearSuggestion = false,
    bool clearAccepted = false,
  }) {
    return JourneyState(
      journey: journey ?? this.journey,
      suggestion: clearSuggestion ? null : suggestion ?? this.suggestion,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      acceptedMessage: clearAccepted
          ? null
          : acceptedMessage ?? this.acceptedMessage,
    );
  }
}

class JourneyController extends StateNotifier<JourneyState> {
  JourneyController(this._repository) : super(const JourneyState());

  final JourneyRepository _repository;

  Future<void> loadCurrent() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final journey = await _repository.currentJourney();
      state = JourneyState(journey: journey);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Journey could not be loaded. Please try again.',
      );
    }
  }

  Future<void> createDraft({required String title}) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Name this weekly journey before starting.',
      );
      return;
    }
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearAccepted: true,
    );
    try {
      final journey = await _repository.createJourney(
        weekStart: _currentWeekStart(),
        title: normalizedTitle,
      );
      state = JourneyState(journey: journey);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Journey could not be updated. Please try again.',
      );
    }
  }

  Future<void> addSession({
    required String title,
    required String category,
    required String priority,
    required int estimatedMinutes,
    String? note,
  }) async {
    final journey = state.journey;
    if (journey == null) {
      state = state.copyWith(errorMessage: 'Create a weekly journey first.');
      return;
    }
    if (title.trim().isEmpty || estimatedMinutes <= 0) {
      state = state.copyWith(
        errorMessage: 'Add a title and duration for this focus session.',
      );
      return;
    }
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuggestion: true,
      clearAccepted: true,
    );
    try {
      final session = await _repository.addSession(
        journeyId: journey.id,
        title: title.trim(),
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        category: category.trim().toLowerCase(),
        priority: priority.trim().toLowerCase(),
        estimatedMinutes: estimatedMinutes,
      );
      state = JourneyState(
        journey: journey.copyWith(sessions: [...journey.sessions, session]),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Journey could not be updated. Please try again.',
      );
    }
  }

  Future<void> suggest() async {
    final journey = state.journey;
    if (journey == null || journey.sessions.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Add at least one focus session first.',
      );
      return;
    }
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearAccepted: true,
    );
    try {
      final suggestion = await _repository.suggest(journey.id);
      state = state.copyWith(suggestion: suggestion, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Journey could not be updated. Please try again.',
      );
    }
  }

  Future<void> acceptSuggestion() async {
    final journey = state.journey;
    final suggestion = state.suggestion;
    if (journey == null || suggestion == null) {
      state = state.copyWith(
        errorMessage: 'Create a suggested plan before accepting.',
      );
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final accepted = await _repository.accept(
        journeyId: journey.id,
        suggestion: suggestion,
      );
      state = state.copyWith(
        journey: journey.copyWith(status: accepted.status),
        isLoading: false,
        acceptedMessage: 'Your weekly journey is ready for Today.',
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Journey could not be updated. Please try again.',
      );
    }
  }
}

DateTime _currentWeekStart() {
  final now = DateTime.now();
  return DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - DateTime.monday));
}

final journeyControllerProvider =
    StateNotifierProvider<JourneyController, JourneyState>((ref) {
      return JourneyController(ref.watch(journeyRepositoryProvider));
    });
