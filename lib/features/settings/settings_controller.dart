import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_repository.dart';

class SettingsState {
  const SettingsState({
    this.settings,
    this.isLoading = false,
    this.errorMessage,
    this.saved = false,
  });

  final UserSettings? settings;
  final bool isLoading;
  final String? errorMessage;
  final bool saved;
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._repository) : super(const SettingsState());

  final SettingsRepository _repository;

  Future<void> load() async {
    state = const SettingsState(isLoading: true);
    try {
      final settings = await _repository.get();
      state = SettingsState(settings: settings);
    } catch (_) {
      state = const SettingsState(
        errorMessage: 'Settings could not be loaded.',
      );
    }
  }

  Future<void> save(UserSettings updated) async {
    state = SettingsState(settings: state.settings, isLoading: true);
    try {
      final saved = await _repository.update(updated);
      state = SettingsState(settings: saved, saved: true);
    } catch (_) {
      state = SettingsState(
        settings: state.settings,
        errorMessage: 'Settings could not be saved.',
      );
    }
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
      return SettingsController(ref.watch(settingsRepositoryProvider));
    });
