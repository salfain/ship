import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import 'auth_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 25),
      sendTimeout: const Duration(seconds: 25),
      headers: const {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(AuthInterceptor(ref));
  return dio;
});
