import 'package:flutter_test/flutter_test.dart';

import 'package:lumora_fe/features/settings/settings_controller.dart';
import 'package:lumora_fe/features/settings/settings_repository.dart';

class ThrowingSettingsRepository implements SettingsRepository {
  @override
  Future<UserSettings> get() async => throw Exception('net error');

  @override
  Future<UserSettings> update(UserSettings settings) async =>
      throw Exception('net error');
}

void main() {
  test('load sets settings from repository', () async {
    final controller = SettingsController(MockSettingsRepository());

    await controller.load();

    expect(controller.state.isLoading, false);
    expect(controller.state.settings, isNotNull);
    expect(controller.state.settings!.autoOpenReflection, true);
    expect(controller.state.settings!.preferredFocusTime, '09:00');
    expect(controller.state.settings!.maxSessionsPerDay, 5);
    expect(controller.state.settings!.timezone, 'Asia/Ho_Chi_Minh');
  });

  test('save updates settings', () async {
    final controller = SettingsController(MockSettingsRepository());
    await controller.load();

    final updated = controller.state.settings!;
    await controller.save(
      updated.copyWith(autoOpenReflection: false, maxSessionsPerDay: 3),
    );

    expect(controller.state.settings!.autoOpenReflection, false);
    expect(controller.state.settings!.maxSessionsPerDay, 3);
    expect(controller.state.saved, true);
  });

  test('load sets errorMessage on failure', () async {
    final controller = SettingsController(ThrowingSettingsRepository());

    await controller.load();

    expect(controller.state.isLoading, false);
    expect(controller.state.settings, isNull);
    expect(controller.state.errorMessage, isNotNull);
  });
}
