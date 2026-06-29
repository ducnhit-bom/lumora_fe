import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_environment.dart';
import '../../core/network/dio_provider.dart';

class ReflectionQuestion {
  const ReflectionQuestion({required this.sessionId, required this.question});

  final String sessionId;
  final String question;
}

class Reflection {
  const Reflection({
    required this.id,
    required this.journeyId,
    required this.sessionId,
    required this.content,
    required this.createdAt,
    this.mood,
  });

  final String id;
  final String journeyId;
  final String sessionId;
  final String content;
  final String? mood;
  final String createdAt;
}

abstract class ReflectionRepository {
  Future<ReflectionQuestion> question(String sessionId);

  Future<Reflection> save({
    required String sessionId,
    required String content,
    String? mood,
  });
}

class MockReflectionRepository implements ReflectionRepository {
  @override
  Future<ReflectionQuestion> question(String sessionId) async {
    return ReflectionQuestion(
      sessionId: sessionId,
      question: 'What helped you make progress?',
    );
  }

  @override
  Future<Reflection> save({
    required String sessionId,
    required String content,
    String? mood,
  }) async {
    return Reflection(
      id: 'mock-reflection-$sessionId',
      journeyId: 'mock-journey',
      sessionId: sessionId,
      content: content,
      mood: mood,
      createdAt: DateTime.now().toIso8601String(),
    );
  }
}

class ApiReflectionRepository implements ReflectionRepository {
  ApiReflectionRepository(this._dio);

  final Dio _dio;

  @override
  Future<ReflectionQuestion> question(String sessionId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/sessions/$sessionId/reflection-question',
    );
    final data = response.data!;
    return ReflectionQuestion(
      sessionId: data['sessionId'] as String,
      question: data['question'] as String,
    );
  }

  @override
  Future<Reflection> save({
    required String sessionId,
    required String content,
    String? mood,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/reflections',
      data: {
        'sessionId': sessionId,
        'content': content,
        'mood': ?mood,
      },
    );
    final data = response.data!;
    return Reflection(
      id: data['id'] as String,
      journeyId: data['journeyId'] as String,
      sessionId: data['sessionId'] as String,
      content: data['content'] as String,
      mood: data['mood'] as String?,
      createdAt: data['createdAt'] as String,
    );
  }
}

final reflectionRepositoryProvider = Provider<ReflectionRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockReflectionRepository();
  }
  return ApiReflectionRepository(ref.watch(dioProvider));
});
