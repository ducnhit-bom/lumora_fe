import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnvironment { mock, development }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;

  bool get useMockData => environment == AppEnvironment.mock;

  static AppConfig fromEnvironment() {
    const useMockData = bool.fromEnvironment('LUMORA_USE_MOCK_DATA', defaultValue: true);
    const apiBaseUrl = String.fromEnvironment(
      'LUMORA_API_BASE_URL',
      defaultValue: 'http://127.0.0.1:8000',
    );

    return const AppConfig(
      environment: useMockData ? AppEnvironment.mock : AppEnvironment.development,
      apiBaseUrl: apiBaseUrl,
    );
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});
