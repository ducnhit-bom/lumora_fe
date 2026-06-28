import 'package:flutter_test/flutter_test.dart';

import 'package:lumora_fe/features/auth/auth_controller.dart';
import 'package:lumora_fe/features/auth/auth_repository.dart';

class FailingAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> login({required String email, required String password}) async {
    throw Exception('bad credentials');
  }

  @override
  Future<AuthResult> register({required String name, required String email, required String password}) async {
    throw Exception('duplicate email');
  }

  @override
  Future<void> logout(String token) async {
    throw Exception('network down');
  }
}

void main() {
  test('login failure resets loading and shows friendly error', () async {
    final controller = AuthController(FailingAuthRepository());

    await controller.login(email: 'linh@example.com', password: 'secret123');

    expect(controller.state.isLoading, isFalse);
    expect(controller.state.errorMessage, 'Could not sign in. Please try again.');
  });

  test('logout clears local session even when API revoke fails', () async {
    final controller = AuthController.signedInForTest(repository: FailingAuthRepository());

    await controller.logout();

    expect(controller.state.isAuthenticated, isFalse);
  });
}
