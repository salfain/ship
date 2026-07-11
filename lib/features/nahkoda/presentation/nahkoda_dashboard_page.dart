import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/file_validator.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dashboard/presentation/dashboard_widgets.dart';
import '../../location/presentation/ship_map_card.dart';
import '../domain/nahkoda_models.dart';
import 'nahkoda_controller.dart';

class NahkodaDashboardPage extends ConsumerStatefulWidget {
  const NahkodaDashboardPage({super.key});

  @override
  ConsumerState<NahkodaDashboardPage> createState() =>
      _NahkodaDashboardPageState();
}

class _NahkodaDashboardPageState extends ConsumerState<NahkodaDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).session!;
    final state = ref.watch(nahkodaControllerProvider);
    const visual = RoleVisual.nahkoda;

    ref.listen(
      nahkodaControllerProvider.select((value) => value.actionMessage),
      (previous, next) {
        if (next == null || next == previous) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next)));
        ref.read(nahkodaControllerProvider.notifier).clearMessage();
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
          icon: Icon(Icons.assignment_outlined),
          label: 'Pengajuan',
        ),
        NavigationDestination(
          icon: Icon(Icons.location_on_outlined),
          label: 'Lokasi',
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
              onRetry: ref.read(nahkodaControllerProvider.notifier).load,
            ),
          )
        else
          ..._buildTab(context, state, session.name),
      ],
    );
  }

  List<Widget> _buildTab(
    BuildContext context,
    NahkodaState state,
    String userName,
  ) {
    return switch (_selectedIndex) {
      0 => [
        _DashboardTab(
          state: state,
          userName: userName,
          onCreateSubmission: () => _showCreateSubmissionSheet(context),
          onShowHistory: () => setState(() => _selectedIndex = 1),
          onShowProfile: () => setState(() => _selectedIndex = 3),
          onSendLocation: ref
              .read(nahkodaControllerProvider.notifier)
              .sendCurrentLocation,
          onOpenDetail: (submission) => _showDetailSheet(context, submission),
        ),
      ],
      1 => [
        _SubmissionHistoryTab(
          state: state,
          onCreateSubmission: () => _showCreateSubmissionSheet(context),
          onRefresh: ref.read(nahkodaControllerProvider.notifier).load,
          onOpenDetail: (submission) => _showDetailSheet(context, submission),
        ),
      ],
      2 => [
        _LocationTab(
          state: state,
          onSendLocation: ref
              .read(nahkodaControllerProvider.notifier)
              .sendCurrentLocation,
        ),
      ],
      _ => [
        _ProfileTab(
          userName: userName,
          state: state,
          onLogout: ref.read(authControllerProvider.notifier).logout,
        ),
      ],
    };
  }

  Future<void> _showCreateSubmissionSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _CreateSubmissionSheet(),
    );
  }

  Future<void> _showDetailSheet(
    BuildContext context,
    Submission submission,
  ) async {
    final detail = await ref
        .read(nahkodaControllerProvider.notifier)
        .loadSubmissionDetail(submission.id);
    if (!context.mounted || detail == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SubmissionDetailSheet(submission: detail),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.state,
    required this.userName,
    required this.onCreateSubmission,
    required this.onShowHistory,
    required this.onShowProfile,
    required this.onSendLocation,
    required this.onOpenDetail,
  });

  final NahkodaState state;
  final String userName;
  final VoidCallback onCreateSubmission;
  final VoidCallback onShowHistory;
  final VoidCallback onShowProfile;
  final VoidCallback onSendLocation;
  final ValueChanged<Submission> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final ship = state.primaryShip;
    final latest = state.submissions.isEmpty ? null : state.submissions.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RadarStatusCard(
          isSendingLocation: state.isSendingLocation,
          hasLocation: ship?.latestLocation != null,
          onSendLocation: onSendLocation,
        ),
        const SizedBox(height: AppSizes.lg),
        const SectionTitle('Informasi Kapal', actionLabel: 'Lihat Detail'),
        _ShipInfoCard(
          shipName: ship?.name ?? 'Data kapal belum tersedia',
          shipNumber: ship?.shipNumber ?? '-',
        ),
        const SizedBox(height: AppSizes.lg),
        SummaryPanel(
          title: 'Ringkasan Pengajuan',
          subtitle: 'Per hari ini',
          accent: AppColors.ocean,
          metrics: [
            DashboardMetric(
              label: 'Total',
              value: '${state.total}',
              icon: Icons.folder_copy_outlined,
              color: AppColors.info,
            ),
            DashboardMetric(
              label: 'Pending',
              value: '${state.pending}',
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
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        SectionTitle(
          'Pengajuan Terbaru',
          actionLabel: 'Lihat Semua',
          onAction: onShowHistory,
        ),
        if (latest == null)
          const AppCard(
            child: EmptyView(
              title: 'Belum ada pengajuan',
              message: 'Buat pengajuan berlabuh pertama untuk kapal Anda.',
              icon: Icons.assignment_outlined,
            ),
          )
        else
          SubmissionTile(
            code: latest.shortCode,
            primary: latest.ship?.name ?? userName,
            secondary:
                '${DateFormatter.formatDateTime(latest.submittedAt)} - ${latest.cargoAmount}',
            status: latest.status,
            onTap: () => onOpenDetail(latest),
          ),
        const SizedBox(height: AppSizes.lg),
        const SectionTitle('Menu Cepat'),
        QuickActionGrid(
          accent: AppColors.ocean,
          actions: [
            QuickAction(
              label: 'Buat Pengajuan',
              icon: Icons.add_box_outlined,
              onTap: onCreateSubmission,
            ),
            QuickAction(
              label: 'Kirim Lokasi',
              icon: Icons.my_location,
              onTap: onSendLocation,
            ),
            QuickAction(
              label: 'Riwayat',
              icon: Icons.history_rounded,
              onTap: onShowHistory,
            ),
            QuickAction(
              label: 'Profil',
              icon: Icons.account_circle_outlined,
              onTap: onShowProfile,
            ),
          ],
        ),
      ],
    );
  }
}

class _SubmissionHistoryTab extends StatelessWidget {
  const _SubmissionHistoryTab({
    required this.state,
    required this.onCreateSubmission,
    required this.onRefresh,
    required this.onOpenDetail,
  });

  final NahkodaState state;
  final VoidCallback onCreateSubmission;
  final VoidCallback onRefresh;
  final ValueChanged<Submission> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchBarMock(
          hint: 'Cari nomor pengajuan...',
          trailingIcon: Icons.filter_list_rounded,
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Buat Pengajuan',
                icon: Icons.add,
                onPressed: onCreateSubmission,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
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
        const SectionTitle('Riwayat Pengajuan'),
        if (state.submissions.isEmpty)
          const AppCard(
            child: EmptyView(
              title: 'Riwayat kosong',
              message: 'Belum ada pengajuan yang tercatat.',
              icon: Icons.history_rounded,
            ),
          )
        else
          for (final submission in state.submissions) ...[
            SubmissionTile(
              code: submission.shortCode,
              primary: submission.ship?.name ?? submission.captainName,
              secondary:
                  '${DateFormatter.formatDateTime(submission.submittedAt)} - ${submission.cargo}',
              status: submission.status,
              onTap: () => onOpenDetail(submission),
            ),
            const SizedBox(height: AppSizes.sm),
          ],
      ],
    );
  }
}

class _LocationTab extends StatelessWidget {
  const _LocationTab({required this.state, required this.onSendLocation});

  final NahkodaState state;
  final VoidCallback onSendLocation;

  @override
  Widget build(BuildContext context) {
    final ship = state.primaryShip;
    final location = ship?.latestLocation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RadarStatusCard(
          isSendingLocation: state.isSendingLocation,
          hasLocation: location != null,
          onSendLocation: onSendLocation,
        ),
        const SizedBox(height: AppSizes.lg),
        const SectionTitle('Lokasi Kapal'),
        ShipMapCard(
          points: _mapPointsFromShip(ship),
          accent: AppColors.ocean,
          onRefresh: onSendLocation,
          isRefreshing: state.isSendingLocation,
          emptyMessage: 'Tekan kirim lokasi untuk menampilkan posisi kapal.',
        ),
        const SizedBox(height: AppSizes.md),
        AppCard(
          child: Column(
            children: [
              InfoRow(label: 'Kapal', value: ship?.name ?? '-'),
              const SizedBox(height: AppSizes.sm),
              InfoRow(label: 'Nomor Kapal', value: ship?.shipNumber ?? '-'),
              const SizedBox(height: AppSizes.sm),
              InfoRow(
                label: 'Latitude',
                value: location == null ? '-' : '${location.latitude}',
              ),
              const SizedBox(height: AppSizes.sm),
              InfoRow(
                label: 'Longitude',
                value: location == null ? '-' : '${location.longitude}',
              ),
              const SizedBox(height: AppSizes.sm),
              InfoRow(
                label: 'Update Terakhir',
                value: DateFormatter.formatDateTime(location?.createdAt),
              ),
              const SizedBox(height: AppSizes.lg),
              AppButton(
                label: 'Kirim Lokasi Sekarang',
                icon: Icons.my_location,
                isLoading: state.isSendingLocation,
                onPressed: onSendLocation,
              ),
            ],
          ),
        ),
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
  final NahkodaState state;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final ship = state.primaryShip;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Profil'),
        AppCard(
          child: Column(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.sky,
                child: Text(
                  userName.isEmpty ? 'N' : userName.characters.first,
                  style: const TextStyle(
                    color: AppColors.ocean,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
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
                'Nakhoda',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: AppSizes.lg),
              InfoRow(label: 'Kapal', value: ship?.name ?? '-'),
              const SizedBox(height: AppSizes.sm),
              InfoRow(label: 'Nomor Kapal', value: ship?.shipNumber ?? '-'),
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

class _RadarStatusCard extends StatelessWidget {
  const _RadarStatusCard({
    required this.isSendingLocation,
    required this.hasLocation,
    required this.onSendLocation,
  });

  final bool isSendingLocation;
  final bool hasLocation;
  final VoidCallback onSendLocation;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.sky,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.ocean.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radius),
            ),
            child: const Icon(Icons.location_on, color: AppColors.ocean),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasLocation ? 'Radar Aktif' : 'Lokasi Belum Dikirim',
                  style: const TextStyle(
                    color: AppColors.ocean,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasLocation
                      ? 'Lokasi kapal terakhir sudah tercatat'
                      : 'Kirim koordinat kapal ke sistem KSOP',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          IconButton.filled(
            tooltip: 'Kirim lokasi',
            onPressed: isSendingLocation ? null : onSendLocation,
            icon: isSendingLocation
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ShipInfoCard extends StatelessWidget {
  const _ShipInfoCard({required this.shipName, required this.shipNumber});

  final String shipName;
  final String shipNumber;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 82,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.sky,
              borderRadius: BorderRadius.circular(AppSizes.radius),
            ),
            child: const Icon(
              Icons.directions_boat_filled,
              color: AppColors.ocean,
              size: 38,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shipNumber,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  shipName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: AppSizes.sm),
                const Row(
                  children: [
                    Expanded(
                      child: InfoRow(label: 'GT / Kapasitas', value: '1200 GT'),
                    ),
                    SizedBox(width: AppSizes.md),
                    Expanded(
                      child: InfoRow(
                        label: 'Jenis Kapal',
                        value: 'Kapal Kargo',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          const StatusBadge(status: 'APPROVED'),
        ],
      ),
    );
  }
}

class _CreateSubmissionSheet extends ConsumerStatefulWidget {
  const _CreateSubmissionSheet();

  @override
  ConsumerState<_CreateSubmissionSheet> createState() =>
      _CreateSubmissionSheetState();
}

class _CreateSubmissionSheetState
    extends ConsumerState<_CreateSubmissionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _captainController = TextEditingController();
  final _employeeController = TextEditingController();
  final _cargoController = TextEditingController();
  final _cargoAmountController = TextEditingController();

  XFile? _sailingPermit;
  XFile? _callSignCertificate;
  XFile? _safetyCertificate;
  XFile? _radioStationPermit;
  String? _fileError;

  @override
  void dispose() {
    _captainController.dispose();
    _employeeController.dispose();
    _cargoController.dispose();
    _cargoAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(_DocumentKind kind) async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'PDF',
          extensions: ['pdf'],
          mimeTypes: ['application/pdf'],
        ),
      ],
    );
    if (file == null) return;
    final error = FileValidator.validatePdf(
      fileName: file.name,
      sizeBytes: await file.length(),
      mimeType: file.mimeType,
    );
    if (error != null) {
      setState(() => _fileError = error);
      return;
    }
    setState(() {
      _fileError = null;
      switch (kind) {
        case _DocumentKind.sailingPermit:
          _sailingPermit = file;
        case _DocumentKind.callSignCertificate:
          _callSignCertificate = file;
        case _DocumentKind.safetyCertificate:
          _safetyCertificate = file;
        case _DocumentKind.radioStationPermit:
          _radioStationPermit = file;
      }
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_sailingPermit == null ||
        _callSignCertificate == null ||
        _safetyCertificate == null ||
        _radioStationPermit == null) {
      setState(() => _fileError = 'Keempat dokumen PDF wajib diunggah.');
      return;
    }

    final success = await ref
        .read(nahkodaControllerProvider.notifier)
        .createSubmission(
          CreateSubmissionPayload(
            captainName: _captainController.text.trim(),
            employeeCount: int.parse(_employeeController.text.trim()),
            cargo: _cargoController.text.trim(),
            cargoAmount: _cargoAmountController.text.trim(),
            sailingPermit: _sailingPermit!,
            callSignCertificate: _callSignCertificate!,
            safetyCertificate: _safetyCertificate!,
            radioStationPermit: _radioStationPermit!,
          ),
        );
    if (!mounted || !success) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nahkodaControllerProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.lg,
        right: AppSizes.lg,
        top: AppSizes.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSizes.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Buat Pengajuan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              AppTextField(
                controller: _captainController,
                label: 'Nama Nakhoda',
                prefixIcon: Icons.person_outline,
                validator: _required,
              ),
              const SizedBox(height: AppSizes.md),
              AppTextField(
                controller: _employeeController,
                label: 'Jumlah Pegawai',
                prefixIcon: Icons.groups_outlined,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final required = _required(value);
                  if (required != null) return required;
                  final number = int.tryParse(value!.trim());
                  if (number == null || number <= 0) {
                    return 'Jumlah pegawai harus angka lebih dari 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.md),
              AppTextField(
                controller: _cargoController,
                label: 'Muatan',
                prefixIcon: Icons.inventory_2_outlined,
                validator: _required,
              ),
              const SizedBox(height: AppSizes.md),
              AppTextField(
                controller: _cargoAmountController,
                label: 'Jumlah Muatan',
                prefixIcon: Icons.shopping_bag_outlined,
                validator: _required,
              ),
              const SizedBox(height: AppSizes.lg),
              const SectionTitle('Dokumen PDF'),
              _FilePickTile(
                title: 'Surat Izin Berlayar',
                file: _sailingPermit,
                onTap: () => _pickFile(_DocumentKind.sailingPermit),
              ),
              _FilePickTile(
                title: 'Surat Tanda Panggilan',
                file: _callSignCertificate,
                onTap: () => _pickFile(_DocumentKind.callSignCertificate),
              ),
              _FilePickTile(
                title: 'Sertifikat Keselamatan',
                file: _safetyCertificate,
                onTap: () => _pickFile(_DocumentKind.safetyCertificate),
              ),
              _FilePickTile(
                title: 'Izin Stasiun Radio',
                file: _radioStationPermit,
                onTap: () => _pickFile(_DocumentKind.radioStationPermit),
              ),
              if (_fileError != null) ...[
                const SizedBox(height: AppSizes.sm),
                Text(
                  _fileError!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: AppSizes.lg),
              AppButton(
                label: 'Kirim Pengajuan',
                icon: Icons.send_outlined,
                isLoading: state.isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Field ini wajib diisi.';
    return null;
  }
}

class _FilePickTile extends StatelessWidget {
  const _FilePickTile({
    required this.title,
    required this.file,
    required this.onTap,
  });

  final String title;
  final XFile? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf_outlined, color: AppColors.danger),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _SelectedFileLabel(file: file),
                ],
              ),
            ),
            TextButton(onPressed: onTap, child: const Text('Pilih')),
          ],
        ),
      ),
    );
  }
}

class _SelectedFileLabel extends StatelessWidget {
  const _SelectedFileLabel({required this.file});

  final XFile? file;

  @override
  Widget build(BuildContext context) {
    final selectedFile = file;
    if (selectedFile == null) {
      return const Text(
        'Pilih file PDF maksimal 4 MB',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10, color: AppColors.muted),
      );
    }

    return FutureBuilder<int>(
      future: selectedFile.length(),
      builder: (context, snapshot) {
        final size = snapshot.data;
        final detail = size == null
            ? selectedFile.name
            : '${selectedFile.name} - ${FileValidator.formatSize(size)}';
        return Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: AppColors.muted),
        );
      },
    );
  }
}

class _SubmissionDetailSheet extends StatelessWidget {
  const _SubmissionDetailSheet({required this.submission});

  final Submission submission;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.lg),
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
          ],
        ),
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

List<ShipMapPoint> _mapPointsFromShip(ShipSummary? ship) {
  final location = ship?.latestLocation;
  if (ship == null || location == null) return const [];
  return [
    ShipMapPoint(
      id: ship.id.isEmpty ? ship.shipNumber : ship.id,
      title: '${ship.shipNumber} - ${ship.name}',
      subtitle: DateFormatter.formatDateTime(location.createdAt),
      latitude: location.latitude,
      longitude: location.longitude,
    ),
  ];
}

enum _DocumentKind {
  sailingPermit,
  callSignCertificate,
  safetyCertificate,
  radioStationPermit,
}
