import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_environment.dart';
import '../../core/network/dio_provider.dart';

class TodayPlan {
  const TodayPlan({required this.date, required this.sessions});

  final String date;
  final List<TodaySession> sessions;
}

class TodaySession {
  const TodaySession({
    required this.id,
    required this.journeyId,
    required this.title,
    required this.category,
    required this.priority,
    required this.estimatedMinutes,
    required this.status,
    this.note,
    this.scheduledDate,
    this.scheduledTime,
    this.completedAt,
    this.skippedAt,
  });

  final String id;
  final String journeyId;
  final String title;
  final String? note;
  final String category;
  final String priority;
  final int estimatedMinutes;
  final String? scheduledDate;
  final String? scheduledTime;
  final String status;
  final String? completedAt;
  final String? skippedAt;

  TodaySession copyWith({
    String? status,
    String? completedAt,
    String? skippedAt,
    bool clearCompletedAt = false,
    bool clearSkippedAt = false,
  }) {
    return TodaySession(
      id: id,
      journeyId: journeyId,
      title: title,
      note: note,
      category: category,
      priority: priority,
      estimatedMinutes: estimatedMinutes,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      status: status ?? this.status,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      skippedAt: clearSkippedAt ? null : skippedAt ?? this.skippedAt,
    );
  }
}

class CompleteResult {
  const CompleteResult({
    required this.sessionId,
    required this.status,
    required this.completedAt,
    required this.openReflection,
  });

  final String sessionId;
  final String status;
  final String completedAt;
  final bool openReflection;
}

class UndoCompleteResult {
  const UndoCompleteResult({required this.sessionId, required this.status});

  final String sessionId;
  final String status;
}

class SkipResult {
  const SkipResult({
    required this.sessionId,
    required this.status,
    required this.skippedAt,
  });

  final String sessionId;
  final String status;
  final String skippedAt;
}

abstract class TodayRepository {
  Future<TodayPlan> today();

  Future<TodaySession> detail(String sessionId);

  Future<CompleteResult> complete(String sessionId);

  Future<UndoCompleteResult> undoComplete(String sessionId);

  Future<SkipResult> skip(String sessionId);
}

class MockTodayRepository implements TodayRepository {
  var _session = const TodaySession(
    id: 'mock-session-today',
    journeyId: 'mock-journey',
    title: 'Protect one calm focus block',
    note: 'A light placeholder from mock mode.',
    category: 'work',
    priority: 'high',
    estimatedMinutes: 45,
    scheduledDate: 'today',
    scheduledTime: '09:00',
    status: 'scheduled',
  );

  @override
  Future<TodayPlan> today() async =>
      TodayPlan(date: _todayString(), sessions: [_session]);

  @override
  Future<TodaySession> detail(String sessionId) async => _session;

  @override
  Future<CompleteResult> complete(String sessionId) async {
    final completedAt = DateTime.now().toIso8601String();
    _session = _session.copyWith(
      status: 'completed',
      completedAt: completedAt,
      clearSkippedAt: true,
    );
    return CompleteResult(
      sessionId: sessionId,
      status: 'completed',
      completedAt: completedAt,
      openReflection: true,
    );
  }

  @override
  Future<UndoCompleteResult> undoComplete(String sessionId) async {
    _session = _session.copyWith(status: 'scheduled', clearCompletedAt: true);
    return UndoCompleteResult(sessionId: sessionId, status: 'scheduled');
  }

  @override
  Future<SkipResult> skip(String sessionId) async {
    final skippedAt = DateTime.now().toIso8601String();
    _session = _session.copyWith(
      status: 'skipped',
      skippedAt: skippedAt,
      clearCompletedAt: true,
    );
    return SkipResult(
      sessionId: sessionId,
      status: 'skipped',
      skippedAt: skippedAt,
    );
  }
}

class ApiTodayRepository implements TodayRepository {
  ApiTodayRepository(this._dio);

  final Dio _dio;

  @override
  Future<TodayPlan> today() async {
    final response = await _dio.get<Map<String, dynamic>>('/sessions/today');
    final data = response.data!;
    return TodayPlan(
      date: data['date'] as String,
      sessions: (data['sessions'] as List<dynamic>)
          .map((item) => _session(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<TodaySession> detail(String sessionId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/sessions/$sessionId',
    );
    return _session(response.data!);
  }

  @override
  Future<CompleteResult> complete(String sessionId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/sessions/$sessionId/complete',
    );
    final data = response.data!;
    return CompleteResult(
      sessionId: data['sessionId'] as String,
      status: data['status'] as String,
      completedAt: data['completedAt'] as String,
      openReflection: data['openReflection'] as bool,
    );
  }

  @override
  Future<UndoCompleteResult> undoComplete(String sessionId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/sessions/$sessionId/undo-complete',
    );
    final data = response.data!;
    return UndoCompleteResult(
      sessionId: data['sessionId'] as String,
      status: data['status'] as String,
    );
  }

  @override
  Future<SkipResult> skip(String sessionId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/sessions/$sessionId/skip',
    );
    final data = response.data!;
    return SkipResult(
      sessionId: data['sessionId'] as String,
      status: data['status'] as String,
      skippedAt: data['skippedAt'] as String,
    );
  }
}

TodaySession _session(Map<String, dynamic> data) {
  return TodaySession(
    id: data['id'] as String,
    journeyId: data['journeyId'] as String,
    title: data['title'] as String,
    note: data['note'] as String?,
    category: data['category'] as String,
    priority: data['priority'] as String,
    estimatedMinutes: data['estimatedMinutes'] as int,
    scheduledDate: data['scheduledDate'] as String?,
    scheduledTime: data['scheduledTime'] as String?,
    status: data['status'] as String,
    completedAt: data['completedAt'] as String?,
    skippedAt: data['skippedAt'] as String?,
  );
}

String _todayString() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}

final todayRepositoryProvider = Provider<TodayRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockTodayRepository();
  }
  return ApiTodayRepository(ref.watch(dioProvider));
});
