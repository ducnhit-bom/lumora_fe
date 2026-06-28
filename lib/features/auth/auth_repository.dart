import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_environment.dart';

class AuthResult {
  const AuthResult({
    required this.accessToken,
    required this.email,
  });

  final String accessToken;
  final String email;
}

abstract class AuthRepository {
  Future<AuthResult> login({required String email, required String password});

  Future<AuthResult> register({required String name, required String email, required String password});

  Future<void> logout(String token);
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> login({required String email, required String password}) async {
    return AuthResult(accessToken: 'mock-token-${email.trim().toLowerCase()}', email: email.trim().toLowerCase());
  }

  @override
  Future<AuthResult> register({required String name, required String email, required String password}) async {
    return login(email: email, password: password);
  }

  @override
  Future<void> logout(String token) async {}
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._dio);

  final Dio _dio;

  @override
  Future<AuthResult> login({required String email, required String password}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email.trim().toLowerCase(), 'password': password},
    );
    return _result(response.data!);
  }

  @override
  Future<AuthResult> register({required String name, required String email, required String password}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'name': name.trim(), 'email': email.trim().toLowerCase(), 'password': password},
    );
    return _result(response.data!);
  }

  @override
  Future<void> logout(String token) async {
    await _dio.post<void>('/auth/logout', options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  AuthResult _result(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>;
    return AuthResult(accessToken: data['accessToken'] as String, email: user['email'] as String);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockAuthRepository();
  }

  return ApiAuthRepository(
    Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {'Accept': 'application/json'},
      ),
    ),
  );
});
