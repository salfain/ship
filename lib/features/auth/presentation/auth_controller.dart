import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';
import '../domain/user_session.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

enum AuthStatus { checking, unauthenticated, loading, authenticated }

class AuthState {
  const AuthState({required this.status, this.session, this.errorMessage});

  final AuthStatus status;
  final UserSession? session;
  final String? errorMessage;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && session != null;

  factory AuthState.checking() {
    return const AuthState(status: AuthStatus.checking);
  }

  factory AuthState.unauthenticated({String? errorMessage}) {
    return AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: errorMessage,
    );
  }

  factory AuthState.loading() {
    return const AuthState(status: AuthStatus.loading);
  }

  factory AuthState.authenticated(UserSession session) {
    return AuthState(status: AuthStatus.authenticated, session: session);
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(_restoreSession);
    return AuthState.checking();
  }

  Future<void> _restoreSession() async {
    final session = await ref.read(authRepositoryProvider).restoreSession();
    if (session == null ||
        session.token.isEmpty ||
        session.role == UserRole.unknown) {
      state = AuthState.unauthenticated();
      return;
    }
    state = AuthState.authenticated(session);
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    if (state.status == AuthStatus.loading) return;
    state = AuthState.loading();
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .login(username: username, password: password);
      state = AuthState.authenticated(session);
    } on ApiException catch (error) {
      state = AuthState.unauthenticated(errorMessage: error.message);
    } catch (_) {
      state = AuthState.unauthenticated(
        errorMessage: 'Login gagal. Silakan coba lagi.',
      );
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = AuthState.unauthenticated();
  }

  void clearError() {
    if (state.status == AuthStatus.unauthenticated &&
        state.errorMessage != null) {
      state = AuthState.unauthenticated();
    }
  }
}
