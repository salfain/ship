import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/user_session.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(dioProvider),
    ref.read(secureStorageServiceProvider),
  );
});

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final SecureStorageService _storage;

  Future<UserSession?> restoreSession() {
    return _storage.readSession();
  }

  Future<void> saveSession(UserSession session) {
    return _storage.saveSession(session);
  }

  Future<UserSession> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'auth/login',
        data: {'username': username.trim(), 'password': password},
      );
      final body = response.data;
      final token = body?['token'] as String?;
      final data = body?['data'];

      if (token == null || token.isEmpty || data is! Map<String, dynamic>) {
        throw const ApiException('Data login tidak valid dari server.');
      }

      final session = UserSession.fromLogin(
        token: token,
        data: data,
        fallbackUsername: username,
      );
      await _storage.saveSession(session);
      return session;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> logout() => _storage.clearSession();
}
