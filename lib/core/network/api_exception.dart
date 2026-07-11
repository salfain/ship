import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final serverMessage = _extractMessage(error.response?.data);
    return ApiException(
      serverMessage ?? _fallbackMessage(statusCode, error.type),
      statusCode: statusCode,
    );
  }

  static String? _extractMessage(Object? data) {
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return null;
  }

  static String _fallbackMessage(int? statusCode, DioExceptionType type) {
    if (statusCode == 400) return 'Data yang dikirim belum sesuai.';
    if (statusCode == 401) return 'Sesi login berakhir. Silakan login ulang.';
    if (statusCode == 403) return 'Anda tidak memiliki akses untuk aksi ini.';
    if (statusCode == 404) return 'Data tidak ditemukan.';
    if (statusCode == 409) return 'Data tidak dapat diproses karena konflik.';
    if (statusCode != null && statusCode >= 500) {
      return 'Server sedang bermasalah. Coba lagi nanti.';
    }

    if (type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.sendTimeout) {
      return 'Koneksi terlalu lama. Periksa internet lalu coba lagi.';
    }

    return 'Terjadi gangguan jaringan. Silakan coba lagi.';
  }

  @override
  String toString() => message;
}
