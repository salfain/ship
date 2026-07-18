import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dashboard/presentation/dashboard_widgets.dart';
import '../../location/presentation/ship_map_card.dart';
import '../../nahkoda/domain/nahkoda_models.dart';
import '../domain/admin_models.dart';
import 'admin_controller.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  int _selectedIndex = 0;
  String _statusFilter = 'SEMUA';

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).session!;
    final state = ref.watch(adminControllerProvider);
    const visual = RoleVisual.admin;

    ref.listen(adminControllerProvider.select((value) => value.actionMessage), (
      previous,
      next,
    ) {
      if (next == null || next == previous) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      ref.read(adminControllerProvider.notifier).clearMessage();
    });

    return RoleScaffold(
      visual: visual,
      session: session,
      currentIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Beranda'),
        NavigationDestination(
          icon: Icon(Icons.assignment_turned_in_outlined),
          label: 'Pengajuan',
        ),
        NavigationDestination(
          icon: Icon(Icons.directions_boat_outlined),
          label: 'Kapal',
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
              onRetry: ref.read(adminControllerProvider.notifier).load,
            ),
          )
        else
          ..._buildTab(context, state, session.name),
      ],
    );
  }

  List<Widget> _buildTab(
    BuildContext context,
    AdminState state,
    String userName,
  ) {
    return switch (_selectedIndex) {
      0 => [
        _AdminHomeTab(
          state: state,
          onShowSubmissions: () => setState(() => _selectedIndex = 1),
          onShowShips: () => setState(() => _selectedIndex = 2),
          onShowLocations: () => setState(() => _selectedIndex = 3),
          onOpenDetail: (submission) =>
              _showSubmissionDetail(context, submission),
        ),
      ],
      1 => [
        _SubmissionVerificationTab(
          state: state,
          statusFilter: _statusFilter,
          onFilterChanged: (value) => setState(() => _statusFilter = value),
          onRefresh: ref.read(adminControllerProvider.notifier).load,
          onOpenDetail: (submission) =>
              _showSubmissionDetail(context, submission),
        ),
      ],
      2 => [
        _ShipsTab(
          state: state,
          onOpenHistory: (ship) => _showShipHistory(context, ship.shipNumber),
        ),
      ],
      3 => [
        _LocationTab(
          state: state,
          onRefresh: ref.read(adminControllerProvider.notifier).load,
        ),
      ],
      _ => [
        _ProfileTab(
          userName: userName,
          state: state,
          onCreateUser: () => _showCreateUserSheet(context, state.ships),
          onCreateShip: () => _showCreateShipSheet(context),
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
        .read(adminControllerProvider.notifier)
        .loadSubmissionDetail(submission.id);
    if (!context.mounted || detail == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AdminSubmissionDetailSheet(submission: detail),
    );
  }

  Future<void> _showShipHistory(BuildContext context, String shipNumber) async {
    await ref
        .read(adminControllerProvider.notifier)
        .loadShipHistory(shipNumber);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ShipHistorySheet(),
    );
  }

  Future<void> _showCreateUserSheet(
    BuildContext context,
    List<ShipSummary> ships,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CreateUserSheet(ships: ships),
    );
  }

  Future<void> _showCreateShipSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _CreateShipSheet(),
    );
  }
}

class _AdminHomeTab extends StatelessWidget {
  const _AdminHomeTab({
    required this.state,
    required this.onShowSubmissions,
    required this.onShowShips,
    required this.onShowLocations,
    required this.onOpenDetail,
  });

  final AdminState state;
  final VoidCallback onShowSubmissions;
  final VoidCallback onShowShips;
  final VoidCallback onShowLocations;
  final ValueChanged<Submission> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final pending = state.pendingSubmissions.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SummaryPanel(
          title: 'Ringkasan Pengajuan',
          subtitle: 'Per hari ini',
          accent: AppColors.admin,
          metrics: [
            DashboardMetric(
              label: 'Total Masuk',
              value: '${state.total}',
              icon: Icons.inbox_outlined,
            ),
            DashboardMetric(
              label: 'Menunggu Verifikasi',
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
          'Pengajuan Perlu Dicek',
          actionLabel: 'Lihat Semua',
          onAction: onShowSubmissions,
        ),
        if (pending.isEmpty)
          const AppCard(
            child: EmptyView(
              title: 'Tidak ada antrian',
              message: 'Pengajuan pending akan tampil di sini.',
              icon: Icons.fact_check_outlined,
            ),
          )
        else
          for (final submission in pending) ...[
            SubmissionTile(
              code: submission.shortCode,
              primary:
                  '${submission.captainName} - ${submission.ship?.name ?? '-'}',
              secondary: DateFormatter.formatDateTime(submission.submittedAt),
              status: submission.status,
              icon: Icons.person_outline,
              onTap: () => onOpenDetail(submission),
            ),
            const SizedBox(height: AppSizes.sm),
          ],
        const SizedBox(height: AppSizes.lg),
        const SectionTitle('Menu Cepat'),
        QuickActionGrid(
          accent: AppColors.admin,
          actions: [
            QuickAction(
              label: 'Verifikasi Pengajuan',
              icon: Icons.fact_check_outlined,
              onTap: onShowSubmissions,
            ),
            QuickAction(
              label: 'Lokasi Kapal',
              icon: Icons.location_on_outlined,
              onTap: onShowLocations,
            ),
            QuickAction(
              label: 'Cek Kedatangan',
              icon: Icons.checklist_outlined,
              onTap: onShowSubmissions,
            ),
            QuickAction(
              label: 'Semua Kapal',
              icon: Icons.directions_boat_outlined,
              onTap: onShowShips,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        SectionTitle(
          'Lokasi Kapal',
          actionLabel: 'Pantau',
          onAction: onShowLocations,
        ),
        ShipMapCard(
          points: _mapPointsFromLocations(state.locations),
          accent: AppColors.admin,
          height: 146,
        ),
        const SizedBox(height: AppSizes.sm),
        for (final location in state.locations.take(2)) ...[
          _ShipLocationRow(location: location),
          const SizedBox(height: AppSizes.sm),
        ],
      ],
    );
  }
}

class _SubmissionVerificationTab extends StatelessWidget {
  const _SubmissionVerificationTab({
    required this.state,
    required this.statusFilter,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.onOpenDetail,
  });

  final AdminState state;
  final String statusFilter;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onRefresh;
  final ValueChanged<Submission> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final filtered = statusFilter == 'SEMUA'
        ? state.submissions
        : state.submissions
              .where((item) => item.status.toUpperCase() == statusFilter)
              .toList();
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
                      label: 'Semua',
                      value: 'SEMUA',
                      selected: statusFilter == 'SEMUA',
                      onSelected: onFilterChanged,
                    ),
                    _StatusFilterChip(
                      label: 'Menunggu',
                      value: 'PENDING',
                      selected: statusFilter == 'PENDING',
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
        const SectionTitle('Daftar Pengajuan'),
        if (filtered.isEmpty)
          const AppCard(
            child: EmptyView(
              title: 'Tidak ada pengajuan',
              message: 'Data pengajuan sesuai filter akan tampil di sini.',
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
              icon: Icons.lock_outline,
              onTap: () => onOpenDetail(submission),
            ),
            const SizedBox(height: AppSizes.sm),
          ],
      ],
    );
  }
}

class _ShipsTab extends StatelessWidget {
  const _ShipsTab({required this.state, required this.onOpenHistory});

  final AdminState state;
  final ValueChanged<ShipSummary> onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SearchBarMock(hint: 'Cari nomor kapal...'),
        const SizedBox(height: AppSizes.lg),
        SectionTitle('Semua Kapal (${state.ships.length})'),
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

class _LocationTab extends StatelessWidget {
  const _LocationTab({required this.state, required this.onRefresh});

  final AdminState state;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: 'Semua Kapal',
                items: const [
                  DropdownMenuItem(
                    value: 'Semua Kapal',
                    child: Text('Semua Kapal'),
                  ),
                ],
                onChanged: null,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.tune)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        ShipMapCard(
          points: _mapPointsFromLocations(state.locations),
          accent: AppColors.admin,
          onRefresh: onRefresh,
          isRefreshing: state.isRefreshing,
        ),
        const SizedBox(height: AppSizes.lg),
        SectionTitle(
          'Lokasi Kapal Aktif (${state.activeShips}/${state.locations.length})',
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
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.userName,
    required this.state,
    required this.onCreateUser,
    required this.onCreateShip,
    required this.onLogout,
  });

  final String userName;
  final AdminState state;
  final VoidCallback onCreateUser;
  final VoidCallback onCreateShip;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Profil Admin'),
        AppCard(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.mint,
                child: Icon(
                  Icons.admin_panel_settings_outlined,
                  color: AppColors.admin,
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
                'Admin / Tata Usaha KSOP',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: AppSizes.lg),
              InfoRow(label: 'Total Pengajuan', value: '${state.total}'),
              const SizedBox(height: AppSizes.sm),
              InfoRow(label: 'Kapal Terdaftar', value: '${state.ships.length}'),
              const SizedBox(height: AppSizes.sm),
              InfoRow(label: 'Kapal Aktif', value: '${state.activeShips}'),
              const SizedBox(height: AppSizes.lg),
              AppButton(
                label: 'Tambah Pengguna',
                icon: Icons.person_add_alt_1_outlined,
                backgroundColor: AppColors.admin,
                onPressed: onCreateUser,
              ),
              const SizedBox(height: AppSizes.sm),
              AppButton(
                label: 'Tambah Kapal',
                icon: Icons.add_circle_outline_rounded,
                backgroundColor: AppColors.admin,
                onPressed: onCreateShip,
              ),
              const SizedBox(height: AppSizes.sm),
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

class _CreateShipSheet extends ConsumerStatefulWidget {
  const _CreateShipSheet();

  @override
  ConsumerState<_CreateShipSheet> createState() => _CreateShipSheetState();
}

class _CreateShipSheetState extends ConsumerState<_CreateShipSheet> {
  final _formKey = GlobalKey<FormState>();
  final _shipNumberController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _shipNumberController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminControllerProvider);
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
                      'Tambah Kapal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: state.isActing
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              AppTextField(
                controller: _shipNumberController,
                label: 'Nomor kapal',
                hintText: 'Contoh: KM-004',
                prefixIcon: Icons.confirmation_number_outlined,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final shipNumber = value?.trim() ?? '';
                  if (!RegExp(
                    r'^[a-zA-Z0-9][a-zA-Z0-9 ._/-]{1,31}$',
                  ).hasMatch(shipNumber)) {
                    return 'Nomor kapal harus 2-32 karakter yang valid.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.md),
              AppTextField(
                controller: _nameController,
                label: 'Nama kapal',
                hintText: 'Contoh: Nusantara Bahari',
                prefixIcon: Icons.directions_boat_outlined,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.length < 2 || name.length > 80) {
                    return 'Nama kapal harus 2-80 karakter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.lg),
              AppButton(
                label: 'Simpan Kapal',
                icon: Icons.save_outlined,
                backgroundColor: AppColors.admin,
                isLoading: state.isActing,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(adminControllerProvider.notifier)
        .createShip(
          CreateShipPayload(
            shipNumber: _shipNumberController.text.trim().toUpperCase(),
            name: _nameController.text.trim(),
          ),
        );
    if (mounted && success) Navigator.of(context).pop();
  }
}

class _CreateUserSheet extends ConsumerStatefulWidget {
  const _CreateUserSheet({required this.ships});

  final List<ShipSummary> ships;

  @override
  ConsumerState<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends ConsumerState<_CreateUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String _role = 'NAHKODA';
  String? _shipId;

  List<ShipSummary> get _availableShips =>
      widget.ships.where((ship) => ship.captain == null).toList();

  @override
  void initState() {
    super.initState();
    final ships = _availableShips;
    if (ships.isNotEmpty) _shipId = ships.first.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminControllerProvider);
    final ships = _availableShips;
    final needsShip = _role == 'NAHKODA';

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
                      'Tambah Pengguna',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: state.isActing
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              AppTextField(
                controller: _nameController,
                label: 'Nama lengkap',
                prefixIcon: Icons.badge_outlined,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().length < 2) {
                    return 'Nama minimal 2 karakter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.md),
              AppTextField(
                controller: _usernameController,
                label: 'Username',
                prefixIcon: Icons.alternate_email_rounded,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final username = value?.trim() ?? '';
                  if (!RegExp(r'^[a-zA-Z0-9._-]{3,32}$').hasMatch(username)) {
                    return 'Gunakan 3-32 huruf, angka, titik, _ atau -.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.md),
              AppTextField(
                controller: _passwordController,
                label: 'Password',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if ((value ?? '').length < 8) {
                    return 'Password minimal 8 karakter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.md),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.manage_accounts_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'NAHKODA', child: Text('Nakhoda')),
                  DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                  DropdownMenuItem(value: 'MANAGER', child: Text('Manager')),
                ],
                onChanged: state.isActing
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _role = value;
                          _shipId = value == 'NAHKODA' && ships.isNotEmpty
                              ? ships.first.id
                              : null;
                        });
                      },
              ),
              if (needsShip) ...[
                const SizedBox(height: AppSizes.md),
                if (ships.isEmpty)
                  const AppCard(
                    child: EmptyView(
                      title: 'Tidak ada kapal tersedia',
                      message: 'Semua kapal sudah memiliki akun Nakhoda.',
                      icon: Icons.directions_boat_outlined,
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    key: ValueKey(_shipId),
                    initialValue: _shipId,
                    decoration: const InputDecoration(
                      labelText: 'Kapal Nakhoda',
                      prefixIcon: Icon(Icons.directions_boat_outlined),
                    ),
                    items: ships
                        .map(
                          (ship) => DropdownMenuItem(
                            value: ship.id,
                            child: Text('${ship.shipNumber} - ${ship.name}'),
                          ),
                        )
                        .toList(),
                    validator: (value) => value == null
                        ? 'Kapal wajib dipilih untuk Nakhoda.'
                        : null,
                    onChanged: state.isActing
                        ? null
                        : (value) => setState(() => _shipId = value),
                  ),
              ],
              const SizedBox(height: AppSizes.lg),
              AppButton(
                label: 'Buat Akun',
                icon: Icons.person_add_alt_1_outlined,
                backgroundColor: AppColors.admin,
                isLoading: state.isActing,
                onPressed: needsShip && ships.isEmpty ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(adminControllerProvider.notifier)
        .createUser(
          CreateUserPayload(
            name: _nameController.text.trim(),
            username: _usernameController.text.trim().toLowerCase(),
            password: _passwordController.text,
            role: _role,
            shipId: _role == 'NAHKODA' ? _shipId : null,
          ),
        );
    if (mounted && success) Navigator.of(context).pop();
  }
}

class _AdminSubmissionDetailSheet extends ConsumerWidget {
  const _AdminSubmissionDetailSheet({required this.submission});

  final Submission submission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminControllerProvider);
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
            const SizedBox(height: AppSizes.md),
            AppButton(
              label: 'Cek Kedatangan Kapal',
              icon: Icons.checklist_outlined,
              isSecondary: true,
              onPressed: () =>
                  _showInspectionSheet(context, ref, submission.id),
            ),
            if (submission.status.toUpperCase() == 'PENDING') ...[
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
                      backgroundColor: AppColors.admin,
                      isLoading: state.isActing,
                      onPressed: () async {
                        await ref
                            .read(adminControllerProvider.notifier)
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
            hintText: 'Tuliskan catatan penolakan',
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
        .read(adminControllerProvider.notifier)
        .rejectSubmission(id: submission.id, reviewNote: note);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _showInspectionSheet(
    BuildContext context,
    WidgetRef ref,
    String submissionId,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _InspectionSheet(submissionId: submissionId),
    );
  }
}

class _InspectionSheet extends ConsumerStatefulWidget {
  const _InspectionSheet({required this.submissionId});

  final String submissionId;

  @override
  ConsumerState<_InspectionSheet> createState() => _InspectionSheetState();
}

class _InspectionSheetState extends ConsumerState<_InspectionSheet> {
  final _noteController = TextEditingController();
  final Map<int, bool> _answers = {};

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminControllerProvider);
    final checklist = state.checklist;
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
                const Expanded(
                  child: Text(
                    'Cek Kedatangan Kapal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            if (checklist.isEmpty)
              const EmptyView(
                title: 'Checklist belum tersedia',
                message: 'Item checklist akan mengikuti data backend.',
              )
            else
              for (final item in checklist) ...[
                AppCard(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.itemNo}. ${item.question}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('YA')),
                          ButtonSegment(value: false, label: Text('TIDAK')),
                        ],
                        selected: {_answers[item.itemNo] ?? true},
                        onSelectionChanged: (value) {
                          setState(() => _answers[item.itemNo] = value.first);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
              ],
            const SizedBox(height: AppSizes.md),
            TextField(
              controller: _noteController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Catatan pemeriksaan',
                hintText: 'Tambahkan catatan jika diperlukan',
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            AppButton(
              label: 'Simpan Hasil Cek',
              icon: Icons.save_outlined,
              backgroundColor: AppColors.admin,
              isLoading: state.isActing,
              onPressed: checklist.isEmpty ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final checklist = ref.read(adminControllerProvider).checklist;
    final items = checklist
        .map(
          (item) => InspectionItemPayload(
            itemNo: item.itemNo,
            condition: (_answers[item.itemNo] ?? true) ? 'YA' : 'TIDAK',
          ),
        )
        .toList();
    await ref
        .read(adminControllerProvider.notifier)
        .saveInspection(
          submissionId: widget.submissionId,
          items: items,
          note: _noteController.text.trim(),
        );
    if (mounted) Navigator.of(context).pop();
  }
}

class _ShipHistorySheet extends ConsumerWidget {
  const _ShipHistorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminControllerProvider);
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
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(AppSizes.radius),
              ),
              child: const Icon(
                Icons.directions_boat_filled,
                color: AppColors.admin,
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
              color: (active ? AppColors.admin : AppColors.warning).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radius),
            ),
            child: Icon(
              Icons.directions_boat_filled,
              color: active ? AppColors.admin : AppColors.warning,
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
