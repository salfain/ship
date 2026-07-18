import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/network/api_exception.dart';
import '../data/nahkoda_repository.dart';
import '../domain/nahkoda_models.dart';

final nahkodaControllerProvider =
    NotifierProvider<NahkodaController, NahkodaState>(NahkodaController.new);

class NahkodaState {
  const NahkodaState({
    this.isLoading = true,
    this.isRefreshing = false,
    this.isSubmitting = false,
    this.isSendingLocation = false,
    this.ships = const [],
    this.submissions = const [],
    this.selectedSubmission,
    this.errorMessage,
    this.actionMessage,
  });

  final bool isLoading;
  final bool isRefreshing;
  final bool isSubmitting;
  final bool isSendingLocation;
  final List<ShipSummary> ships;
  final List<Submission> submissions;
  final Submission? selectedSubmission;
  final String? errorMessage;
  final String? actionMessage;

  ShipSummary? get primaryShip => ships.isEmpty ? null : ships.first;

  int get total => submissions.length;
  int get pending => submissions
      .where((item) => item.status.toUpperCase() == 'PENDING')
      .length;
  int get approved => submissions
      .where((item) => item.status.toUpperCase() == 'APPROVED')
      .length;
  int get rejected => submissions
      .where((item) => item.status.toUpperCase() == 'REJECTED')
      .length;

  NahkodaState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    bool? isSubmitting,
    bool? isSendingLocation,
    List<ShipSummary>? ships,
    List<Submission>? submissions,
    Submission? selectedSubmission,
    bool clearSelectedSubmission = false,
    String? errorMessage,
    bool clearError = false,
    String? actionMessage,
    bool clearActionMessage = false,
  }) {
    return NahkodaState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSendingLocation: isSendingLocation ?? this.isSendingLocation,
      ships: ships ?? this.ships,
      submissions: submissions ?? this.submissions,
      selectedSubmission: clearSelectedSubmission
          ? null
          : selectedSubmission ?? this.selectedSubmission,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      actionMessage: clearActionMessage
          ? null
          : actionMessage ?? this.actionMessage,
    );
  }
}

class NahkodaController extends Notifier<NahkodaState> {
  @override
  NahkodaState build() {
    Future.microtask(load);
    return const NahkodaState();
  }

  Future<void> load() async {
    state = state.copyWith(
      isLoading: state.ships.isEmpty && state.submissions.isEmpty,
      isRefreshing: state.ships.isNotEmpty || state.submissions.isNotEmpty,
      clearError: true,
      clearActionMessage: true,
    );

    try {
      final repository = ref.read(nahkodaRepositoryProvider);
      final results = await Future.wait([
        repository.getMyShips(),
        repository.getMyHistory(),
      ]);
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        ships: results[0] as List<ShipSummary>,
        submissions: results[1] as List<Submission>,
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: error.message,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: 'Gagal memuat data Nakhoda.',
      );
    }
  }

  Future<Submission?> loadSubmissionDetail(String id) async {
    try {
      final detail = await ref
          .read(nahkodaRepositoryProvider)
          .getSubmissionDetail(id);
      state = state.copyWith(selectedSubmission: detail);
      return detail;
    } on ApiException catch (error) {
      state = state.copyWith(actionMessage: error.message);
    } catch (_) {
      state = state.copyWith(actionMessage: 'Gagal memuat detail pengajuan.');
    }
    return null;
  }

  Future<bool> createSubmission(CreateSubmissionPayload payload) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, clearActionMessage: true);
    try {
      final created = await ref
          .read(nahkodaRepositoryProvider)
          .createSubmission(payload);
      final updated = [created, ...state.submissions];
      state = state.copyWith(
        isSubmitting: false,
        submissions: updated,
        actionMessage: 'Pengajuan berhasil dikirim.',
      );
      await load();
      state = state.copyWith(actionMessage: 'Pengajuan berhasil dikirim.');
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(isSubmitting: false, actionMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        actionMessage: 'Pengajuan gagal dikirim.',
      );
    }
    return false;
  }

  Future<void> sendCurrentLocation() async {
    if (state.isSendingLocation) return;
    state = state.copyWith(isSendingLocation: true, clearActionMessage: true);

    try {
      if (!_isLocationOriginAllowed()) {
        state = state.copyWith(
          isSendingLocation: false,
          actionMessage:
              'Lokasi Chrome hanya tersedia melalui HTTPS atau localhost.',
        );
        return;
      }

      if (!kIsWeb) {
        final enabled = await Geolocator.isLocationServiceEnabled();
        if (!enabled) {
          state = state.copyWith(
            isSendingLocation: false,
            actionMessage: 'GPS belum aktif. Aktifkan lokasi perangkat.',
          );
          return;
        }

        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          state = state.copyWith(
            isSendingLocation: false,
            actionMessage:
                'Izin lokasi diperlukan untuk mengirim posisi kapal.',
          );
          return;
        }
      }

      final locationSettings = kIsWeb
          ? WebSettings(
              accuracy: LocationAccuracy.high,
              maximumAge: Duration(minutes: 5),
              timeLimit: Duration(seconds: 20),
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 20),
            );
      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(const Duration(seconds: 20));
      final savedLocation = await ref
          .read(nahkodaRepositoryProvider)
          .updateLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          );
      final updatedShips = state.ships
          .map(
            (ship) => ship.id == state.primaryShip?.id
                ? ship.copyWith(latestLocation: savedLocation)
                : ship,
          )
          .toList();
      state = state.copyWith(
        isSendingLocation: false,
        ships: updatedShips,
        actionMessage: 'Lokasi kapal berhasil dikirim.',
      );
      await load();
    } on TimeoutException {
      state = state.copyWith(
        isSendingLocation: false,
        actionMessage:
            'Lokasi tidak ditemukan dalam 20 detik. Pastikan izin lokasi Chrome dan lokasi perangkat aktif.',
      );
    } on PermissionDeniedException {
      state = state.copyWith(
        isSendingLocation: false,
        actionMessage:
            'Izin lokasi Chrome ditolak. Izinkan Location pada pengaturan situs.',
      );
    } on LocationServiceDisabledException {
      state = state.copyWith(
        isSendingLocation: false,
        actionMessage: 'Layanan lokasi perangkat belum aktif.',
      );
    } on UnsupportedError {
      state = state.copyWith(
        isSendingLocation: false,
        actionMessage:
            'Browser atau alamat Web ini tidak mendukung pengambilan lokasi.',
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        isSendingLocation: false,
        actionMessage: error.message,
      );
    } catch (_) {
      state = state.copyWith(
        isSendingLocation: false,
        actionMessage: 'Gagal mengirim lokasi kapal.',
      );
    }
  }

  void clearMessage() {
    state = state.copyWith(clearActionMessage: true);
  }

  bool _isLocationOriginAllowed() {
    if (!kIsWeb) return true;
    final origin = Uri.base;
    return origin.scheme == 'https' ||
        origin.host == 'localhost' ||
        origin.host == '127.0.0.1' ||
        origin.host == '::1';
  }
}
