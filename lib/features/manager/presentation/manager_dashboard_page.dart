import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../admin/domain/admin_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dashboard/presentation/dashboard_widgets.dart';
import '../../location/presentation/ship_map_card.dart';
import '../../nahkoda/domain/nahkoda_models.dart';
import 'manager_controller.dart';

class ManagerDashboardPage extends ConsumerStatefulWidget {
  const ManagerDashboardPage({super.key});

  @override
  ConsumerState<ManagerDashboardPage> createState() =>
      _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends ConsumerState<ManagerDashboardPage> {
  int _selectedIndex = 0;
  String _statusFilter = 'ANTRIAN';

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).session!;
    final state = ref.watch(managerControllerProvider);
    const visual = RoleVisual.manager;

    ref.listen(
      managerControllerProvider.select((value) => value.actionMessage),
      (previous, next) {
        if (next == null || next == previous) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next)));
        ref.read(managerControllerProvider.notifier).clearMessage();
      },
    );

    return RoleScaffold(
      visual: visual,
      session: session,
      currentIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Beranda'),
        NavigationDestination(
          icon: Icon(Icons.approval_outlined),
          label: 'Keputusan',
        ),
        NavigationDestination(
          icon: Icon(Icons.directions_boat_outlined),
          label: 'Kapal',
        ),
        NavigationDestination(
          icon: Icon(Icons.insert_chart_outlined),
          label: 'Laporan',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profil',
        ),
      ],
      children: [
        if (state.isLoading)
          const SizedBox(height: 360, child: LoadingView())
        else if (state.errorMessage != null)
          SizedBox(
            height: 360,
            child: ErrorView(
              message: state.errorMessage!,
              onRetry: ref.read(managerControllerProvider.notifier).load,
            ),
          )
        else
          ..._buildTab(context, state, session.name),
      ],
    );
  }

  List<Widget> _buildTab(
    BuildContext context,
    ManagerState state,
    String userName,
  ) {
    return switch (_selectedIndex) {
      0 => [
        _ManagerHomeTab(
          state: state,
          onShowDecisions: () => setState(() => _selectedIndex = 1),
          onShowShips: () => setState(() => _selectedIndex = 2),
          onShowReports: () => setState(() => _selectedIndex = 3),
          onOpenDetail: (submission) =>
              _showSubmissionDetail(context, submission),
        ),
      ],
      1 => [
        _DecisionQueueTab(
          state: state,
          statusFilter: _statusFilter,
          onFilterChanged: (value) => setState(() => _statusFilter = value),
          onRefresh: ref.read(managerControllerProvider.notifier).load,
          onOpenDetail: (submission) =>
              _showSubmissionDetail(context, submission),
        ),
      ],
      2 => [
        _ShipsAndLocationTab(
          state: state,
          onRefresh: ref.read(managerControllerProvider.notifier).load,
          onOpenHistory: (ship) => _showShipHistory(context, ship.shipNumber),
        ),
      ],
      3 => [_ReportTab(state: state)],
      _ => [
        _ProfileTab(
          userName: userName,
          state: state,
          onLogout: ref.read(authControllerProvider.notifier).logout,
        ),
      ],
    };
  }

  Future<void> _showSubmissionDetail(
    BuildContext context,
    Submission submission,
  ) async {
    final detail = await ref
        .read(managerControllerProvider.notifier)
        .loadSubmissionDetail(submission.id);
    if (!context.mounted || detail == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ManagerSubmissionDetailSheet(submission: detail),
    );
  }

  Future<void> _showShipHistory(BuildContext context, String shipNumber) async {
    await ref
        .read(managerControllerProvider.notifier)
        .loadShipHistory(shipNumber);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ShipHistorySheet(),
    );
  }
}

class _ManagerHomeTab extends StatelessWidget {
  const _ManagerHomeTab({
    required this.state,
    required this.onShowDecisions,
    required this.onShowShips,
    required this.onShowReports,
    required this.onOpenDetail,
  });

  final ManagerState state;
  final VoidCallback onShowDecisions;
  final VoidCallback onShowShips;
  final VoidCallback onShowReports;
  final ValueChanged<Submission> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final queue = state.decisionQueue.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SummaryPanel(
          title: 'Ringkasan Persetujuan',
          subtitle: 'Per hari ini',
          accent: AppColors.manager,
          metrics: [
            DashboardMetric(
              label: 'Menunggu Keputusan',
              value: '${state.waitingDecision}',
              icon: Icons.hourglass_top_outlined,
              color: AppColors.warning,
            ),
            DashboardMetric(
              label: 'Disetujui',
              value: '${state.approved}',
              icon: Icons.verified_outlined,
              color: AppColors.success,
            ),
            DashboardMetric(
              label: 'Ditolak',
              value: '${state.rejected}',
              icon: Icons.cancel_outlined,
              color: AppColors.danger,
            ),
            DashboardMetric(
              label: 'Total Pengajuan',
              value: '${state.total}',
              icon: Icons.folder_copy_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        SectionTitle(
          'Pengajuan Menunggu Keputusan',
          actionLabel: 'Lihat Semua',
          onAction: onShowDecisions,
        ),
        if (queue.isEmpty)
          const AppCard(
            child: EmptyView(
              title: 'Tidak ada keputusan tertunda',
              message: 'Pengajuan dari Admin akan tampil di sini.',
              icon: Icons.approval_outlined,
            ),
          )
        else
          for (final submission in queue) ...[
            SubmissionTile(
              code: submission.shortCode,
              primary:
                  '${submission.captainName} - ${submission.ship?.name ?? '-'}',
              secondary: DateFormatter.formatDateTime(submission.submittedAt),
              status: submission.status,
              icon: Icons.lock_outline,
              onTap: () => onOpenDetail(submission),
            ),
            const SizedBox(height: AppSizes.sm),
          ],
        const SizedBox(height: AppSizes.lg),
        const SectionTitle('Menu Cepat'),
        QuickActionGrid(
          accent: AppColors.manager,
          actions: [
            QuickAction(
              label: 'Keputusan Akhir',
              icon: Icons.approval_outlined,
              onTap: onShowDecisions,
            ),
            QuickAction(
              label: 'Data Kapal',
              icon: Icons.directions_boat_outlined,
              onTap: onShowShips,
            ),
            QuickAction(
              label: 'Lokasi Kapal',
              icon: Icons.location_on_outlined,
              onTap: onShowShips,
            ),
            QuickAction(
              label: 'Laporan',
              icon: Icons.insert_chart_outlined,
              onTap: onShowReports,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        SectionTitle(
          'Laporan Ringkas',
          actionLabel: 'Buka',
          onAction: onShowReports,
        ),
        const MiniReportCard(accent: AppColors.manager),
        const SizedBox(height: AppSizes.sm),
        _StatisticCard(state: state),
      ],
    );
  }
}

class _DecisionQueueTab extends StatelessWidget {
  const _DecisionQueueTab({
    required this.state,
    required this.statusFilter,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.onOpenDetail,
  });

  final ManagerState state;
  final String statusFilter;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onRefresh;
  final ValueChanged<Submission> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final filtered = switch (statusFilter) {
      'ANTRIAN' => state.decisionQueue,
      'SEMUA' => state.submissions,
      _ =>
        state.submissions
            .where((item) => item.status.toUpperCase() == statusFilter)
            .toList(),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchBarMock(
          hint: 'Cari nomor / nama / pelabuhan...',
          trailingIcon: Icons.filter_list_rounded,
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _StatusFilterChip(
                      label: 'Antrian',
                      value: 'ANTRIAN',
                      selected: statusFilter == 'ANTRIAN',
                      onSelected: onFilterChanged,
                    ),
                    _StatusFilterChip(
                      label: 'Semua',
                      value: 'SEMUA',
                      selected: statusFilter == 'SEMUA',
                      onSelected: onFilterChanged,
                    ),
                    _StatusFilterChip(
                      label: 'Disetujui',
                      value: 'APPROVED',
                      selected: statusFilter == 'APPROVED',
                      onSelected: onFilterChanged,
                    ),
                    _StatusFilterChip(
                      label: 'Ditolak',
                      value: 'REJECTED',
                      selected: statusFilter == 'REJECTED',
                      onSelected: onFilterChanged,
                    ),
                  ],
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Refresh',
              onPressed: state.isRefreshing ? null : onRefresh,
              icon: state.isRefreshing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        const SectionTitle('Daftar Keputusan'),
        if (filtered.isEmpty)
          const AppCard(
            child: EmptyView(
              title: 'Tidak ada pengajuan',
              message: 'Pengajuan sesuai filter akan tampil di sini.',
              icon: Icons.assignment_outlined,
            ),
          )
        else
          for (final submission in filtered) ...[
            SubmissionTile(
              code: submission.shortCode,
              primary:
                  '${submission.captainName} - ${submission.ship?.name ?? '-'}',
              secondary: DateFormatter.formatDateTime(submission.submittedAt),
              status: submission.status,
              icon: Icons.approval_outlined,
              onTap: () => onOpenDetail(submission),
            ),
            const SizedBox(height: AppSizes.sm),
          ],
      ],
    );
  }
}

class _ShipsAndLocationTab extends StatelessWidget {
  const _ShipsAndLocationTab({
    required this.state,
    required this.onRefresh,
    required this.onOpenHistory,
  });

  final ManagerState state;
  final VoidCallback onRefresh;
  final ValueChanged<ShipSummary> onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SearchBarMock(hint: 'Cari nomor kapal...'),
        const SizedBox(height: AppSizes.lg),
        const SectionTitle('Lokasi Kapal'),
        ShipMapCard(
          points: _mapPointsFromLocations(state.locations),
          accent: AppColors.manager,
          onRefresh: onRefresh,
          isRefreshing: state.isRefreshing,
        ),
        const SizedBox(height: AppSizes.lg),
        SectionTitle(
          'Kapal Aktif (${state.activeShips}/${state.locations.length})',
        ),
        if (state.locations.isEmpty)
          const AppCard(
            child: EmptyView(
              title: 'Lokasi belum tersedia',
              message: 'Lokasi kapal dari Nakhoda akan tampil di sini.',
              icon: Icons.location_off_outlined,
            ),
          )
        else
          for (final location in state.locations) ...[
            _ShipLocationRow(location: location),
            const SizedBox(height: AppSizes.sm),
          ],
        const SizedBox(height: AppSizes.lg),
        SectionTitle('Data Kapal (${state.ships.length})'),
        if (state.ships.isEmpty)
          const AppCard(
            child: EmptyView(
              title: 'Data kapal kosong',
              message: 'Kapal yang terdaftar akan tampil di sini.',
              icon: Icons.directions_boat_outlined,
            ),
          )
        else
          for (final ship in state.ships) ...[
            _ShipRow(ship: ship, onTap: () => onOpenHistory(ship)),
            const SizedBox(height: AppSizes.sm),
          ],
      ],
    );
  }
}

class _ReportTab extends StatelessWidget {
  const _ReportTab({required this.state});

  final ManagerState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: '7 Hari Terakhir',
                items: const [
                  DropdownMenuItem(
                    value: '7 Hari Terakhir',
                    child: Text('7 Hari Terakhir'),
                  ),
                ],
                onChanged: null,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.tune)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        const SectionTitle('Grafik Pengajuan'),
        const MiniReportCard(accent: AppColors.manager),
        const SizedBox(height: AppSizes.lg),
        _StatisticCard(state: state),
        const SizedBox(height: AppSizes.lg),
        _ReportBreakdownCard(state: state),
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.userName,
    required this.state,
    required this.onLogout,
  });

  final String userName;
  final ManagerState state;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Profil Manager'),
        AppCard(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.lavender,
                child: Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.manager,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'Manager / Kepala KSOP',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: AppSizes.lg),
              InfoRow(label: 'Total Pengajuan', value: '${state.total}'),
              const SizedBox(height: AppSizes.sm),
              InfoRow(
                label: 'Menunggu Keputusan',
                value: '${state.waitingDecision}',
              ),
              const SizedBox(height: AppSizes.sm),
              InfoRow(label: 'Kapal Terdaftar', value: '${state.ships.length}'),
              const SizedBox(height: AppSizes.lg),
              AppButton(
                label: 'Keluar',
                icon: Icons.logout_rounded,
                isSecondary: true,
                onPressed: onLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ManagerSubmissionDetailSheet extends ConsumerWidget {
  const _ManagerSubmissionDetailSheet({required this.submission});

  final Submission submission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(managerControllerProvider);
    final canDecide = _canDecide(submission.status);
    final decisionEnabled = Env.managerDecisionEnabled;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.lg,
        right: AppSizes.lg,
        top: AppSizes.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSizes.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    submission.shortCode,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                StatusBadge(status: submission.status),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            AppCard(
              child: Column(
                children: [
                  InfoRow(label: 'Nakhoda', value: submission.captainName),
                  const SizedBox(height: AppSizes.sm),
                  InfoRow(label: 'Kapal', value: submission.ship?.name ?? '-'),
                  const SizedBox(height: AppSizes.sm),
                  InfoRow(
                    label: 'Nomor Kapal',
                    value: submission.ship?.shipNumber ?? '-',
                  ),
                  const SizedBox(height: AppSizes.sm),
                  InfoRow(
                    label: 'Tanggal Pengajuan',
                    value: DateFormatter.formatDateTime(submission.submittedAt),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  InfoRow(label: 'Muatan', value: submission.cargo),
                  const SizedBox(height: AppSizes.sm),
                  InfoRow(
                    label: 'Jumlah Muatan',
                    value: submission.cargoAmount,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  InfoRow(
                    label: 'Jumlah Pegawai',
                    value: '${submission.employeeCount} Orang',
                  ),
                  if (submission.reviewNote != null) ...[
                    const Divider(height: AppSizes.xl),
                    InfoRow(label: 'Catatan', value: submission.reviewNote!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            const SectionTitle('Dokumen'),
            for (final document in submission.documents) ...[
              _DocumentUrlTile(document: document),
              const SizedBox(height: AppSizes.sm),
            ],
            if (canDecide && !decisionEnabled) ...[
              const SizedBox(height: AppSizes.md),
              const _ManagerDecisionNotice(),
            ],
            if (canDecide && decisionEnabled) ...[
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Tolak',
                      icon: Icons.close_rounded,
                      isSecondary: true,
                      isLoading: state.isActing,
                      onPressed: () => _showRejectDialog(context, ref),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: AppButton(
                      label: 'Setujui',
                      icon: Icons.check_rounded,
                      backgroundColor: AppColors.manager,
                      isLoading: state.isActing,
                      onPressed: () async {
                        await ref
                            .read(managerControllerProvider.notifier)
                            .approveSubmission(submission.id);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Pengajuan'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Tuliskan alasan keputusan',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note == null || note.isEmpty) return;
    await ref
        .read(managerControllerProvider.notifier)
        .rejectSubmission(id: submission.id, reviewNote: note);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _ShipHistorySheet extends ConsumerWidget {
  const _ShipHistorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(managerControllerProvider);
    return Padding(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'History Kapal',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSizes.lg),
          if (state.shipHistory.isEmpty)
            const EmptyView(
              title: 'History kosong',
              message: 'Tidak ada pengajuan untuk kapal ini.',
            )
          else
            for (final submission in state.shipHistory.take(8)) ...[
              SubmissionTile(
                code: submission.shortCode,
                primary: submission.captainName,
                secondary: DateFormatter.formatDateTime(submission.submittedAt),
                status: submission.status,
              ),
              const SizedBox(height: AppSizes.sm),
            ],
        ],
      ),
    );
  }
}

class _ManagerDecisionNotice extends StatelessWidget {
  const _ManagerDecisionNotice();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      color: AppColors.lavender,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.manager),
          SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              'Keputusan akhir Manager belum aktif di backend. '
              'Endpoint approve/reject saat ini hanya mengizinkan Admin, '
              'jadi aksi Manager ditahan agar tidak muncul akses ditolak.',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentUrlTile extends StatelessWidget {
  const _DocumentUrlTile({required this.document});

  final SubmissionDocument document;

  @override
  Widget build(BuildContext context) {
    final url = document.url;
    return AppCard(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_outlined, color: AppColors.danger),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              document.label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            tooltip: 'Buka dokumen',
            onPressed: url == null || url.isEmpty
                ? null
                : () => _openDocument(context, url),
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
    );
  }

  Future<void> _openDocument(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      _showOpenError(context);
      return;
    }
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) _showOpenError(context);
    } catch (_) {
      if (context.mounted) _showOpenError(context);
    }
  }

  void _showOpenError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dokumen tidak bisa dibuka. Coba refresh detail.'),
      ),
    );
  }
}

class _ShipRow extends StatelessWidget {
  const _ShipRow({required this.ship, required this.onTap});

  final ShipSummary ship;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSizes.md),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(AppSizes.radius),
              ),
              child: const Icon(
                Icons.directions_boat_filled,
                color: AppColors.manager,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${ship.shipNumber} - ${ship.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ship.captain?.name ?? 'Nakhoda belum tersedia',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _ShipLocationRow extends StatelessWidget {
  const _ShipLocationRow({required this.location});

  final ShipLiveLocation location;

  @override
  Widget build(BuildContext context) {
    final active = location.isActive;
    return AppCard(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: (active ? AppColors.manager : AppColors.warning)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radius),
            ),
            child: Icon(
              Icons.directions_boat_filled,
              color: active ? AppColors.manager : AppColors.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${location.shipNumber} - ${location.shipName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Lat ${location.latitude}, Lng ${location.longitude}',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (active ? AppColors.success : AppColors.warning)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.pill),
            ),
            child: Text(
              active ? 'Aktif' : 'Tidak Aktif',
              style: TextStyle(
                color: active ? AppColors.success : AppColors.warning,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({required this.state});

  final ManagerState state;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistik',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSizes.md),
          InfoRow(label: 'Total Pengajuan', value: '${state.total}'),
          const SizedBox(height: AppSizes.sm),
          InfoRow(label: 'Disetujui', value: '${state.approved}'),
          const SizedBox(height: AppSizes.sm),
          InfoRow(label: 'Ditolak', value: '${state.rejected}'),
          const SizedBox(height: AppSizes.sm),
          InfoRow(
            label: 'Menunggu Keputusan',
            value: '${state.waitingDecision}',
          ),
        ],
      ),
    );
  }
}

class _ReportBreakdownCard extends StatelessWidget {
  const _ReportBreakdownCard({required this.state});

  final ManagerState state;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kapal & Lokasi',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSizes.md),
          InfoRow(label: 'Kapal Terdaftar', value: '${state.ships.length}'),
          const SizedBox(height: AppSizes.sm),
          InfoRow(label: 'Lokasi Terkirim', value: '${state.locations.length}'),
          const SizedBox(height: AppSizes.sm),
          InfoRow(label: 'Kapal Aktif', value: '${state.activeShips}'),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(value),
      ),
    );
  }
}

bool _canDecide(String status) {
  final normalized = status.toUpperCase();
  return normalized == 'WAITING_MANAGER_VALIDATION' || normalized == 'PENDING';
}

List<ShipMapPoint> _mapPointsFromLocations(List<ShipLiveLocation> locations) {
  return locations
      .map(
        (location) => ShipMapPoint(
          id: location.shipId.isEmpty ? location.shipNumber : location.shipId,
          title: '${location.shipNumber} - ${location.shipName}',
          subtitle: DateFormatter.formatDateTime(location.updatedAt),
          latitude: location.latitude,
          longitude: location.longitude,
          isActive: location.isActive,
        ),
      )
      .toList();
}
