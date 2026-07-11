import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/nahkoda_models.dart';

final nahkodaRepositoryProvider = Provider<NahkodaRepository>((ref) {
  return NahkodaRepository(ref.read(dioProvider));
});

class NahkodaRepository {
  const NahkodaRepository(this._dio);

  final Dio _dio;

  Future<List<ShipSummary>> getMyShips() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('ships/my');
      final data = _readList(response.data);
      return data.map(ShipSummary.fromJson).toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<Submission>> getMyHistory() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'submissions/my-history',
      );
      final data = _readList(response.data);
      return data.map(Submission.fromJson).toList();
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

  Future<Submission> createSubmission(CreateSubmissionPayload payload) async {
    try {
      final form = FormData.fromMap({
        'captainName': payload.captainName,
        'employeeCount': '${payload.employeeCount}',
        'cargo': payload.cargo,
        'cargoAmount': payload.cargoAmount,
        'sailingPermit': await MultipartFile.fromFile(
          payload.sailingPermit.path,
          filename: payload.sailingPermit.name,
        ),
        'callSignCertificate': await MultipartFile.fromFile(
          payload.callSignCertificate.path,
          filename: payload.callSignCertificate.name,
        ),
        'safetyCertificate': await MultipartFile.fromFile(
          payload.safetyCertificate.path,
          filename: payload.safetyCertificate.name,
        ),
        'radioStationPermit': await MultipartFile.fromFile(
          payload.radioStationPermit.path,
          filename: payload.radioStationPermit.name,
        ),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        'submissions',
        data: form,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Data pengajuan tidak valid dari server.');
      }
      return Submission.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        'location/update',
        data: {'latitude': latitude, 'longitude': longitude},
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
