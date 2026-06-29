import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_environment.dart';
import '../../core/network/dio_provider.dart';

class UserSettings {
  const UserSettings({
    required this.autoOpenReflection,
    required this.preferredFocusTime,
    required this.maxSessionsPerDay,
    required this.timezone,
  });

  final bool autoOpenReflection;
  final String preferredFocusTime;
  final int maxSessionsPerDay;
  final String timezone;

  UserSettings copyWith({
    bool? autoOpenReflection,
    String? preferredFocusTime,
    int? maxSessionsPerDay,
    String? timezone,
  }) {
    return UserSettings(
      autoOpenReflection: autoOpenReflection ?? this.autoOpenReflection,
      preferredFocusTime: preferredFocusTime ?? this.preferredFocusTime,
      maxSessionsPerDay: maxSessionsPerDay ?? this.maxSessionsPerDay,
      timezone: timezone ?? this.timezone,
    );
  }
}

abstract class SettingsRepository {
  Future<UserSettings> get();
  Future<UserSettings> update(UserSettings settings);
}

class MockSettingsRepository implements SettingsRepository {
  UserSettings _settings = const UserSettings(
    autoOpenReflection: true,
    preferredFocusTime: '09:00',
    maxSessionsPerDay: 5,
    timezone: 'Asia/Ho_Chi_Minh',
  );

  @override
  Future<UserSettings> get() async => _settings;

  @override
  Future<UserSettings> update(UserSettings settings) async {
    _settings = settings;
    return _settings;
  }
}

class ApiSettingsRepository implements SettingsRepository {
  ApiSettingsRepository(this._dio);

  final Dio _dio;

  @override
  Future<UserSettings> get() async {
    final response = await _dio.get<Map<String, dynamic>>('/settings');
    return _fromJson(response.data!);
  }

  @override
  Future<UserSettings> update(UserSettings settings) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/settings',
      data: _toJson(settings),
    );
    return _fromJson(response.data!);
  }

  Map<String, dynamic> _toJson(UserSettings s) => {
    'autoOpenReflection': s.autoOpenReflection,
    'preferredFocusTime': s.preferredFocusTime,
    'maxSessionsPerDay': s.maxSessionsPerDay,
    'timezone': s.timezone,
  };

  UserSettings _fromJson(Map<String, dynamic> data) => UserSettings(
    autoOpenReflection: data['autoOpenReflection'] as bool,
    preferredFocusTime: data['preferredFocusTime'] as String,
    maxSessionsPerDay: data['maxSessionsPerDay'] as int,
    timezone: data['timezone'] as String,
  );
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockSettingsRepository();
  }
  return ApiSettingsRepository(ref.watch(dioProvider));
});
