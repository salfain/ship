import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../nahkoda/domain/nahkoda_models.dart';
import '../domain/admin_models.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.read(dioProvider));
});

class AdminRepository {
  const AdminRepository(this._dio);

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
      final response = await _dio.patch<Map<String, dynamic>>(
        'submissions/$id/approve',
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Data approve tidak valid dari server.');
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
      final response = await _dio.patch<Map<String, dynamic>>(
        'submissions/$id/reject',
        data: {'reviewNote': reviewNote},
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Data reject tidak valid dari server.');
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

  Future<List<ChecklistQuestion>> getChecklist() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'submissions/arrival-inspection/checklist',
      );
      return _readList(response.data).map(ChecklistQuestion.fromJson).toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> saveInspection({
    required String submissionId,
    required List<InspectionItemPayload> items,
    String? note,
  }) async {
    try {
      await _dio.put<Map<String, dynamic>>(
        'submissions/$submissionId/arrival-inspection',
        data: FormData.fromMap({
          'inspectionItems': jsonEncode(
            items.map((item) => item.toJson()).toList(),
          ),
          if (note != null && note.trim().isNotEmpty) 'note': note,
        }),
      );
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
