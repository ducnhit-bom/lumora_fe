import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'today_repository.dart';

class TodayState {
  const TodayState({
    this.plan,
    this.selectedSession,
    this.isLoading = false,
    this.errorMessage,
    this.openReflectionSessionId,
  });

  final TodayPlan? plan;
  final TodaySession? selectedSession;
  final bool isLoading;
  final String? errorMessage;
  final String? openReflectionSessionId;

  TodayState copyWith({
    TodayPlan? plan,
    TodaySession? selectedSession,
    bool? isLoading,
    String? errorMessage,
    String? openReflectionSessionId,
    bool clearError = false,
    bool clearReflection = false,
  }) {
    return TodayState(
      plan: plan ?? this.plan,
      selectedSession: selectedSession ?? this.selectedSession,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      openReflectionSessionId: clearReflection
          ? null
          : openReflectionSessionId ?? this.openReflectionSessionId,
    );
  }
}

class TodayController extends StateNotifier<TodayState> {
  TodayController(this._repository) : super(const TodayState());

  final TodayRepository _repository;

  Future<void> loadToday() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final plan = await _repository.today();
      state = TodayState(plan: plan);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Today could not be updated. Please try again.',
      );
    }
  }

  Future<void> loadDetail(String sessionId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _repository.detail(sessionId);
      state = state.copyWith(selectedSession: session, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Today could not be updated. Please try again.',
      );
    }
  }

  Future<void> complete(String sessionId) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearReflection: true,
    );
    try {
      final result = await _repository.complete(sessionId);
      _replaceSession(
        sessionId,
        (session) => session.copyWith(
          status: result.status,
          completedAt: result.completedAt,
          clearSkippedAt: true,
        ),
      );
      state = state.copyWith(
        isLoading: false,
        openReflectionSessionId: result.openReflection ? sessionId : null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Today could not be updated. Please try again.',
      );
    }
  }

  Future<void> undoComplete(String sessionId) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearReflection: true,
    );
    try {
      final result = await _repository.undoComplete(sessionId);
      _replaceSession(
        sessionId,
        (session) =>
            session.copyWith(status: result.status, clearCompletedAt: true),
      );
      state = state.copyWith(isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Today could not be updated. Please try again.',
      );
    }
  }

  Future<void> skip(String sessionId) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearReflection: true,
    );
    try {
      final result = await _repository.skip(sessionId);
      _replaceSession(
        sessionId,
        (session) => session.copyWith(
          status: result.status,
          skippedAt: result.skippedAt,
          clearCompletedAt: true,
        ),
      );
      state = state.copyWith(isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Today could not be updated. Please try again.',
      );
    }
  }

  void _replaceSession(
    String sessionId,
    TodaySession Function(TodaySession session) update,
  ) {
    final plan = state.plan;
    final selectedSession = state.selectedSession;
    final updatedSelected = selectedSession?.id == sessionId
        ? update(selectedSession!)
        : selectedSession;
    if (plan == null) {
      state = state.copyWith(selectedSession: updatedSelected);
      return;
    }
    state = state.copyWith(
      selectedSession: updatedSelected,
      plan: TodayPlan(
        date: plan.date,
        sessions: [
          for (final session in plan.sessions)
            session.id == sessionId ? update(session) : session,
        ],
      ),
    );
  }
}

final todayControllerProvider =
    StateNotifierProvider<TodayController, TodayState>((ref) {
      return TodayController(ref.watch(todayRepositoryProvider));
    });
