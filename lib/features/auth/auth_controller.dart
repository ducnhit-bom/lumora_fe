import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.email,
  });

  final String accessToken;
  final String email;
}

class AuthState {
  const AuthState({
    this.session,
    this.isLoading = false,
    this.errorMessage,
  });

  final AuthSession? session;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => session != null;

  AuthState copyWith({
    AuthSession? session,
    bool? isLoading,
    String? errorMessage,
    bool clearSession = false,
    bool clearError = false,
  }) {
    return AuthState(
      session: clearSession ? null : session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  AuthController.signedInForTest({AuthRepository? repository})
      : _repository = repository ?? MockAuthRepository(),
        super(
          const AuthState(
            session: AuthSession(accessToken: 'test-token', email: 'linh@example.com'),
          ),
        );

  Future<void> login({required String email, required String password}) async {
    await _authenticate(email: email, password: password, isRegister: false);
  }

  Future<void> register({required String name, required String email, required String password}) async {
    await _authenticate(name: name, email: email, password: password, isRegister: true);
  }

  Future<void> logout() async {
    final token = state.session?.accessToken;
    try {
      if (token != null) {
        await _repository.logout(token);
      }
    } catch (_) {
      // Local logout must always win so users are not trapped by a stale token.
    } finally {
      state = state.copyWith(clearSession: true, clearError: true);
    }
  }

  Future<void> _authenticate({String? name, required String email, required String password, required bool isRegister}) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!normalizedEmail.contains('@') || password.length < 6 || (isRegister && (name == null || name.trim().isEmpty))) {
      state = state.copyWith(errorMessage: 'Enter a valid email and password.', isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = isRegister
          ? await _repository.register(name: name!.trim(), email: normalizedEmail, password: password)
          : await _repository.login(email: normalizedEmail, password: password);
      state = AuthState(
        session: AuthSession(accessToken: result.accessToken, email: result.email),
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Could not sign in. Please try again.');
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
