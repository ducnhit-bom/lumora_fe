import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reflection_repository.dart';

class ReflectionState {
  const ReflectionState({
    this.sessionId,
    this.question,
    this.content = '',
    this.mood,
    this.savedReflection,
    this.isLoading = false,
    this.errorMessage,
    this.didSkip = false,
  });

  final String? sessionId;
  final String? question;
  final String content;
  final String? mood;
  final Reflection? savedReflection;
  final bool isLoading;
  final String? errorMessage;
  final bool didSkip;

  ReflectionState copyWith({
    String? sessionId,
    String? question,
    String? content,
    String? mood,
    Reflection? savedReflection,
    bool? isLoading,
    String? errorMessage,
    bool? didSkip,
    bool clearError = false,
  }) {
    return ReflectionState(
      sessionId: sessionId ?? this.sessionId,
      question: question ?? this.question,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      savedReflection: savedReflection ?? this.savedReflection,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      didSkip: didSkip ?? this.didSkip,
    );
  }
}

class ReflectionController extends StateNotifier<ReflectionState> {
  ReflectionController(this._repository) : super(const ReflectionState());

  final ReflectionRepository _repository;

  Future<void> load(String sessionId) async {
    state = ReflectionState(sessionId: sessionId, isLoading: true);
    try {
      final question = await _repository.question(sessionId);
      state = state.copyWith(
        question: question.question,
        isLoading: false,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Reflection could not be loaded. Please try again.',
      );
    }
  }

  void updateContent(String value) {
    state = state.copyWith(content: value, clearError: true);
  }

  void selectMood(String value) {
    state = state.copyWith(mood: value, clearError: true);
  }

  Future<void> save() async {
    final sessionId = state.sessionId;
    final content = state.content.trim();
    if (sessionId == null) return;
    if (content.isEmpty) {
      state = state.copyWith(errorMessage: 'Write a short reflection or skip.');
      return;
    }
    if (content.length > 500) {
      state = state.copyWith(
        errorMessage: 'Reflection must be 500 characters or less.',
      );
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final reflection = await _repository.save(
        sessionId: sessionId,
        content: content,
        mood: state.mood,
      );
      state = state.copyWith(
        isLoading: false,
        savedReflection: reflection,
        didSkip: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Reflection could not be saved. Please try again.',
      );
    }
  }

  void skip() {
    state = state.copyWith(didSkip: true, clearError: true);
  }
}

final reflectionControllerProvider =
    StateNotifierProvider<ReflectionController, ReflectionState>((ref) {
      return ReflectionController(ref.watch(reflectionRepositoryProvider));
    });
