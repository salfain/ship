import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../admin/domain/admin_models.dart';
import '../../nahkoda/domain/nahkoda_models.dart';
import '../data/manager_repository.dart';

final managerControllerProvider =
    NotifierProvider<ManagerController, ManagerState>(ManagerController.new);

class ManagerState {
  const ManagerState({
    this.isLoading = true,
    this.isRefreshing = false,
    this.isActing = false,
    this.submissions = const [],
    this.ships = const [],
    this.locations = const [],
    this.selectedSubmission,
    this.shipHistory = const [],
    this.errorMessage,
    this.actionMessage,
  });

  final bool isLoading;
  final bool isRefreshing;
  final bool isActing;
  final List<Submission> submissions;
  final List<ShipSummary> ships;
  final List<ShipLiveLocation> locations;
  final Submission? selectedSubmission;
  final List<Submission> shipHistory;
  final String? errorMessage;
  final String? actionMessage;

  int get total => submissions.length;
  int get approved => submissions
      .where((item) => item.status.toUpperCase() == 'APPROVED')
      .length;
  int get rejected => submissions
      .where((item) => item.status.toUpperCase() == 'REJECTED')
      .length;
  int get activeShips => locations.where((item) => item.isActive).length;
  int get waitingDecision => decisionQueue.length;

  List<Submission> get decisionQueue =>
      submissions.where((item) => _isDecisionStatus(item.status)).toList();

  ManagerState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    bool? isActing,
    List<Submission>? submissions,
    List<ShipSummary>? ships,
    List<ShipLiveLocation>? locations,
    Submission? selectedSubmission,
    bool clearSelectedSubmission = false,
    List<Submission>? shipHistory,
    String? errorMessage,
    bool clearError = false,
    String? actionMessage,
    bool clearActionMessage = false,
  }) {
    return ManagerState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isActing: isActing ?? this.isActing,
      submissions: submissions ?? this.submissions,
      ships: ships ?? this.ships,
      locations: locations ?? this.locations,
      selectedSubmission: clearSelectedSubmission
          ? null
          : selectedSubmission ?? this.selectedSubmission,
      shipHistory: shipHistory ?? this.shipHistory,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      actionMessage: clearActionMessage
          ? null
          : actionMessage ?? this.actionMessage,
    );
  }
}

class ManagerController extends Notifier<ManagerState> {
  @override
  ManagerState build() {
    Future.microtask(load);
    return const ManagerState();
  }

  Future<void> load() async {
    state = state.copyWith(
      isLoading:
          state.submissions.isEmpty &&
          state.ships.isEmpty &&
          state.locations.isEmpty,
      isRefreshing:
          state.submissions.isNotEmpty ||
          state.ships.isNotEmpty ||
          state.locations.isNotEmpty,
      clearError: true,
      clearActionMessage: true,
    );
    try {
      final repository = ref.read(managerRepositoryProvider);
      final results = await Future.wait([
        repository.getSubmissions(),
        repository.getShips(),
        repository.getShipLocations(),
      ]);
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        submissions: results[0] as List<Submission>,
        ships: results[1] as List<ShipSummary>,
        locations: results[2] as List<ShipLiveLocation>,
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
        errorMessage: 'Gagal memuat data Manager.',
      );
    }
  }

  Future<Submission?> loadSubmissionDetail(String id) async {
    try {
      final detail = await ref
          .read(managerRepositoryProvider)
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

  Future<void> approveSubmission(String id) async {
    if (state.isActing) return;
    state = state.copyWith(isActing: true, clearActionMessage: true);
    try {
      await ref.read(managerRepositoryProvider).approveSubmission(id);
      state = state.copyWith(
        isActing: false,
        actionMessage: 'Keputusan persetujuan berhasil disimpan.',
      );
      await load();
    } on ApiException catch (error) {
      state = state.copyWith(isActing: false, actionMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isActing: false,
        actionMessage: 'Gagal menyetujui pengajuan.',
      );
    }
  }

  Future<void> rejectSubmission({
    required String id,
    required String reviewNote,
  }) async {
    if (state.isActing) return;
    state = state.copyWith(isActing: true, clearActionMessage: true);
    try {
      await ref
          .read(managerRepositoryProvider)
          .rejectSubmission(id: id, reviewNote: reviewNote);
      state = state.copyWith(
        isActing: false,
        actionMessage: 'Keputusan penolakan berhasil disimpan.',
      );
      await load();
    } on ApiException catch (error) {
      state = state.copyWith(isActing: false, actionMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isActing: false,
        actionMessage: 'Gagal menolak pengajuan.',
      );
    }
  }

  Future<void> loadShipHistory(String shipNumber) async {
    state = state.copyWith(isActing: true, clearActionMessage: true);
    try {
      final history = await ref
          .read(managerRepositoryProvider)
          .getShipHistory(shipNumber);
      state = state.copyWith(isActing: false, shipHistory: history);
    } on ApiException catch (error) {
      state = state.copyWith(isActing: false, actionMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isActing: false,
        actionMessage: 'Gagal memuat history kapal.',
      );
    }
  }

  void clearMessage() {
    state = state.copyWith(clearActionMessage: true);
  }
}

bool _isDecisionStatus(String status) {
  final normalized = status.toUpperCase();
  return normalized == 'WAITING_MANAGER_VALIDATION' || normalized == 'PENDING';
}
