import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../admin/domain/admin_models.dart';
import '../../nahkoda/domain/nahkoda_models.dart';

final managerRepositoryProvider = Provider<ManagerRepository>((ref) {
  return ManagerRepository(ref.read(dioProvider));
});

class ManagerRepository {
  const ManagerRepository(this._dio);

  final Dio _dio;

  Future<List<Submission>> getSubmissions({
    String? status,
    String? shipNumber,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'submissions',
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (shipNumber != null && shipNumber.isNotEmpty)
            'shipNumber': shipNumber,
        },
      );
      return _readList(response.data).map(Submission.fromJson).toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Submission> getSubmissionDetail(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('submissions/$id');
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Detail pengajuan tidak valid dari server.');
      }
      return Submission.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Submission> approveSubmission(String id) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        'submissions/$id/manager-validation',
        data: {'decision': 'APPROVED'},
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Data persetujuan tidak valid dari server.');
      }
      return Submission.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Submission> rejectSubmission({
    required String id,
    required String reviewNote,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        'submissions/$id/manager-validation',
        data: {'decision': 'REJECTED', 'reviewNote': reviewNote},
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Data penolakan tidak valid dari server.');
      }
      return Submission.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<ShipSummary>> getShips() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('ships');
      return _readList(response.data).map(ShipSummary.fromJson).toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<Submission>> getShipHistory(String shipNumber) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'submissions/ship/$shipNumber/history',
      );
      return _readList(response.data).map(Submission.fromJson).toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<ShipLiveLocation>> getShipLocations() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('location/ships');
      return _readList(response.data).map(ShipLiveLocation.fromJson).toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  List<Map<String, dynamic>> _readList(Map<String, dynamic>? body) {
    final data = body?['data'];
    if (data is! List) return const [];
    return data.whereType<Map<String, dynamic>>().toList();
  }
}
