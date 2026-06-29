import 'package:flutter_test/flutter_test.dart';

import 'package:lumora_fe/features/reflection/reflection_controller.dart';
import 'package:lumora_fe/features/reflection/reflection_repository.dart';

class FakeReflectionRepository implements ReflectionRepository {
  FakeReflectionRepository({this.fail = false});

  bool fail;
  String? savedContent;
  String? savedMood;

  @override
  Future<ReflectionQuestion> question(String sessionId) async {
    if (fail) throw Exception('network');
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
    if (fail) throw Exception('network');
    savedContent = content;
    savedMood = mood;
    return Reflection(
      id: 'reflection-1',
      journeyId: 'journey-1',
      sessionId: sessionId,
      content: content,
      mood: mood,
      createdAt: '2026-06-29T09:30:00Z',
    );
  }
}

void main() {
  test('loads fallback reflection question', () async {
    final controller = ReflectionController(FakeReflectionRepository());

    await controller.load('session-1');

    expect(controller.state.question, 'What helped you make progress?');
    expect(controller.state.errorMessage, isNull);
  });

  test('save trims content and stores selected mood', () async {
    final repository = FakeReflectionRepository();
    final controller = ReflectionController(repository);

    await controller.load('session-1');
    controller.updateContent('  I found one calm next step.  ');
    controller.selectMood('balanced');
    await controller.save();

    expect(repository.savedContent, 'I found one calm next step.');
    expect(repository.savedMood, 'balanced');
    expect(controller.state.savedReflection?.id, 'reflection-1');
    expect(controller.state.didSkip, isFalse);
  });

  test('rejects reflection content over 500 characters before saving', () async {
    final repository = FakeReflectionRepository();
    final controller = ReflectionController(repository);

    await controller.load('session-1');
    controller.updateContent('x' * 501);
    await controller.save();

    expect(repository.savedContent, isNull);
    expect(controller.state.errorMessage, 'Reflection must be 500 characters or less.');
  });

  test('skip marks local skip without saving', () async {
    final repository = FakeReflectionRepository();
    final controller = ReflectionController(repository);

    await controller.load('session-1');
    controller.skip();

    expect(repository.savedContent, isNull);
    expect(controller.state.didSkip, isTrue);
  });
}
