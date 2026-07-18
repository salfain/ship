import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../nahkoda/domain/nahkoda_models.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';

final adminControllerProvider = NotifierProvider<AdminController, AdminState>(
  AdminController.new,
);

class AdminState {
  const AdminState({
    this.isLoading = true,
    this.isRefreshing = false,
    this.isActing = false,
    this.submissions = const [],
    this.ships = const [],
    this.locations = const [],
    this.checklist = const [],
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
  final List<ChecklistQuestion> checklist;
  final Submission? selectedSubmission;
  final List<Submission> shipHistory;
  final String? errorMessage;
  final String? actionMessage;

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
  int get activeShips => locations.where((item) => item.isActive).length;

  List<Submission> get pendingSubmissions => submissions
      .where((item) => item.status.toUpperCase() == 'PENDING')
      .toList();

  AdminState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    bool? isActing,
    List<Submission>? submissions,
    List<ShipSummary>? ships,
    List<ShipLiveLocation>? locations,
    List<ChecklistQuestion>? checklist,
    Submission? selectedSubmission,
    bool clearSelectedSubmission = false,
    List<Submission>? shipHistory,
    String? errorMessage,
    bool clearError = false,
    String? actionMessage,
    bool clearActionMessage = false,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isActing: isActing ?? this.isActing,
      submissions: submissions ?? this.submissions,
      ships: ships ?? this.ships,
      locations: locations ?? this.locations,
      checklist: checklist ?? this.checklist,
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

class AdminController extends Notifier<AdminState> {
  @override
  AdminState build() {
    Future.microtask(load);
    return const AdminState();
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
      final repository = ref.read(adminRepositoryProvider);
      final results = await Future.wait([
        repository.getSubmissions(),
        repository.getShips(),
        repository.getShipLocations(),
        repository.getChecklist(),
      ]);
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        submissions: results[0] as List<Submission>,
        ships: results[1] as List<ShipSummary>,
        locations: results[2] as List<ShipLiveLocation>,
        checklist: results[3] as List<ChecklistQuestion>,
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
        errorMessage: 'Gagal memuat data Admin.',
      );
    }
  }

  Future<Submission?> loadSubmissionDetail(String id) async {
    try {
      final detail = await ref
          .read(adminRepositoryProvider)
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

  Future<bool> createUser(CreateUserPayload payload) async {
    if (state.isActing) return false;
    state = state.copyWith(isActing: true, clearActionMessage: true);
    try {
      await ref.read(adminRepositoryProvider).createUser(payload);
      state = state.copyWith(
        isActing: false,
        actionMessage: 'Akun pengguna berhasil dibuat.',
      );
      await load();
      state = state.copyWith(actionMessage: 'Akun pengguna berhasil dibuat.');
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(isActing: false, actionMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isActing: false,
        actionMessage: 'Gagal membuat akun pengguna.',
      );
    }
    return false;
  }

  Future<bool> createShip(CreateShipPayload payload) async {
    if (state.isActing) return false;
    state = state.copyWith(isActing: true, clearActionMessage: true);
    try {
      await ref.read(adminRepositoryProvider).createShip(payload);
      state = state.copyWith(
        isActing: false,
        actionMessage: 'Kapal berhasil ditambahkan.',
      );
      await load();
      state = state.copyWith(actionMessage: 'Kapal berhasil ditambahkan.');
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(isActing: false, actionMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isActing: false,
        actionMessage: 'Gagal menambahkan kapal.',
      );
    }
    return false;
  }

  Future<void> approveSubmission(String id) async {
    if (state.isActing) return;
    state = state.copyWith(isActing: true, clearActionMessage: true);
    try {
      await ref.read(adminRepositoryProvider).approveSubmission(id);
      state = state.copyWith(
        isActing: false,
        actionMessage: 'Pengajuan berhasil disetujui.',
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
          .read(adminRepositoryProvider)
          .rejectSubmission(id: id, reviewNote: reviewNote);
      state = state.copyWith(
        isActing: false,
        actionMessage: 'Pengajuan berhasil ditolak.',
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
          .read(adminRepositoryProvider)
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

  Future<void> saveInspection({
    required String submissionId,
    required List<InspectionItemPayload> items,
    String? note,
  }) async {
    if (state.isActing) return;
    state = state.copyWith(isActing: true, clearActionMessage: true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .saveInspection(submissionId: submissionId, items: items, note: note);
      state = state.copyWith(
        isActing: false,
        actionMessage: 'Hasil cek kedatangan berhasil disimpan.',
      );
    } on ApiException catch (error) {
      state = state.copyWith(isActing: false, actionMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isActing: false,
        actionMessage: 'Gagal menyimpan cek kedatangan.',
      );
    }
  }

  void clearMessage() {
    state = state.copyWith(clearActionMessage: true);
  }
}
