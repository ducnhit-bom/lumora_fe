import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_environment.dart';
import '../../core/network/dio_provider.dart';

class Journey {
  const Journey({
    required this.id,
    required this.weekStart,
    required this.title,
    required this.status,
    required this.sessions,
  });

  final String id;
  final DateTime weekStart;
  final String title;
  final String status;
  final List<FocusSession> sessions;

  Journey copyWith({String? status, List<FocusSession>? sessions}) {
    return Journey(
      id: id,
      weekStart: weekStart,
      title: title,
      status: status ?? this.status,
      sessions: sessions ?? this.sessions,
    );
  }
}

class FocusSession {
  const FocusSession({
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
}

class SuggestedJourney {
  const SuggestedJourney({required this.source, required this.days});

  final String source;
  final List<SuggestedDay> days;
}

class SuggestedDay {
  const SuggestedDay({required this.date, required this.sessions});

  final String date;
  final List<SuggestedSession> sessions;
}

class SuggestedSession {
  const SuggestedSession({
    required this.sessionId,
    required this.suggestedTime,
    required this.reason,
  });

  final String sessionId;
  final String suggestedTime;
  final String reason;
}

class AcceptedJourney {
  const AcceptedJourney({
    required this.id,
    required this.status,
    required this.acceptedAt,
  });

  final String id;
  final String status;
  final String acceptedAt;
}

abstract class JourneyRepository {
  Future<Journey?> currentJourney();

  Future<Journey> createJourney({
    required DateTime weekStart,
    required String title,
  });

  Future<FocusSession> addSession({
    required String journeyId,
    required String title,
    required String category,
    required String priority,
    required int estimatedMinutes,
    String? note,
  });

  Future<SuggestedJourney> suggest(String journeyId);

  Future<AcceptedJourney> accept({
    required String journeyId,
    required SuggestedJourney suggestion,
  });
}

class MockJourneyRepository implements JourneyRepository {
  Journey? _journey;
  var _sessionCount = 0;

  @override
  Future<Journey?> currentJourney() async => _journey;

  @override
  Future<Journey> createJourney({
    required DateTime weekStart,
    required String title,
  }) async {
    _journey = Journey(
      id: 'mock-journey-${weekStart.toIso8601String()}',
      weekStart: weekStart,
      title: title,
      status: 'draft',
      sessions: const [],
    );
    return _journey!;
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
    _sessionCount += 1;
    final session = FocusSession(
      id: 'mock-session-$_sessionCount',
      journeyId: journeyId,
      title: title,
      note: note,
      category: category,
      priority: priority,
      estimatedMinutes: estimatedMinutes,
      status: 'todo',
    );
    _journey = _journey?.copyWith(sessions: [..._journey!.sessions, session]);
    return session;
  }

  @override
  Future<SuggestedJourney> suggest(String journeyId) async {
    final sessions = _journey?.sessions ?? const <FocusSession>[];
    final weekStart = _journey?.weekStart ?? _currentWeekStart();
    final days = <String, List<SuggestedSession>>{};
    for (var i = 0; i < sessions.length; i += 1) {
      final session = sessions[i];
      final date = _formatDate(weekStart.add(Duration(days: i % 7)));
      days
          .putIfAbsent(date, () => [])
          .add(
            SuggestedSession(
              sessionId: session.id,
              suggestedTime: session.priority == 'high' ? '09:00' : '10:30',
              reason: session.priority == 'high'
                  ? 'Start fresh.'
                  : 'Keep steady progress.',
            ),
          );
    }
    return SuggestedJourney(
      source: 'fallback',
      days: days.entries
          .map((entry) => SuggestedDay(date: entry.key, sessions: entry.value))
          .toList(),
    );
  }

  @override
  Future<AcceptedJourney> accept({
    required String journeyId,
    required SuggestedJourney suggestion,
  }) async {
    _journey = _journey?.copyWith(status: 'active');
    return AcceptedJourney(
      id: journeyId,
      status: 'active',
      acceptedAt: DateTime.now().toIso8601String(),
    );
  }
}

class ApiJourneyRepository implements JourneyRepository {
  ApiJourneyRepository(this._dio);

  final Dio _dio;

  @override
  Future<Journey?> currentJourney() async {
    final response = await _dio.get<Map<String, dynamic>>('/journeys/current');
    final data = response.data!;
    if (data['journey'] == null && !data.containsKey('id')) {
      return null;
    }
    return _journey(data);
  }

  @override
  Future<Journey> createJourney({
    required DateTime weekStart,
    required String title,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/journeys',
      data: {'weekStart': _formatDate(weekStart), 'title': title},
    );
    return _journey(response.data!);
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
    final response = await _dio.post<Map<String, dynamic>>(
      '/journeys/$journeyId/sessions',
      data: {
        'title': title,
        'note': note,
        'category': category,
        'priority': priority,
        'estimatedMinutes': estimatedMinutes,
      },
    );
    return _session(response.data!);
  }

  @override
  Future<SuggestedJourney> suggest(String journeyId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/journeys/$journeyId/suggest',
    );
    return _suggestion(response.data!);
  }

  @override
  Future<AcceptedJourney> accept({
    required String journeyId,
    required SuggestedJourney suggestion,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/journeys/$journeyId/accept',
      data: {
        'days': [
          for (final day in suggestion.days)
            {
              'date': day.date,
              'sessions': [
                for (final session in day.sessions)
                  {
                    'sessionId': session.sessionId,
                    'suggestedTime': session.suggestedTime,
                  },
              ],
            },
        ],
      },
    );
    final data = response.data!;
    return AcceptedJourney(
      id: data['id'] as String,
      status: data['status'] as String,
      acceptedAt: data['acceptedAt'] as String,
    );
  }
}

Journey _journey(Map<String, dynamic> data) {
  final sessions = (data['sessions'] as List<dynamic>? ?? const [])
      .map((item) => _session(item as Map<String, dynamic>))
      .toList();
  return Journey(
    id: data['id'] as String,
    weekStart: DateTime.parse(data['weekStart'] as String),
    title: data['title'] as String,
    status: data['status'] as String,
    sessions: sessions,
  );
}

FocusSession _session(Map<String, dynamic> data) {
  return FocusSession(
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
  );
}

SuggestedJourney _suggestion(Map<String, dynamic> data) {
  return SuggestedJourney(
    source: data['source'] as String,
    days: (data['days'] as List<dynamic>)
        .map(
          (day) => SuggestedDay(
            date: (day as Map<String, dynamic>)['date'] as String,
            sessions: (day['sessions'] as List<dynamic>)
                .map(
                  (session) => SuggestedSession(
                    sessionId:
                        (session as Map<String, dynamic>)['sessionId']
                            as String,
                    suggestedTime: session['suggestedTime'] as String,
                    reason: session['reason'] as String? ?? '',
                  ),
                )
                .toList(),
          ),
        )
        .toList(),
  );
}

DateTime _currentWeekStart() {
  final now = DateTime.now();
  return DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - DateTime.monday));
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockJourneyRepository();
  }
  return ApiJourneyRepository(ref.watch(dioProvider));
});
