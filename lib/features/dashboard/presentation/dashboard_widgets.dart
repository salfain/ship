import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/domain/user_session.dart';
import '../../auth/presentation/auth_controller.dart';

class RoleVisual {
  const RoleVisual({
    required this.title,
    required this.accent,
    required this.soft,
    required this.icon,
  });

  final String title;
  final Color accent;
  final Color soft;
  final IconData icon;

  static const nahkoda = RoleVisual(
    title: 'Dashboard Nakhoda',
    accent: AppColors.ocean,
    soft: AppColors.sky,
    icon: Icons.directions_boat_filled,
  );

  static const admin = RoleVisual(
    title: 'Dashboard Admin',
    accent: AppColors.admin,
    soft: AppColors.mint,
    icon: Icons.admin_panel_settings_outlined,
  );

  static const manager = RoleVisual(
    title: 'Dashboard Manager',
    accent: AppColors.manager,
    soft: AppColors.lavender,
    icon: Icons.verified_user_outlined,
  );
}

class RoleScaffold extends ConsumerWidget {
  const RoleScaffold({
    required this.visual,
    required this.session,
    required this.currentIndex,
    required this.destinations,
    required this.children,
    this.onDestinationSelected,
    super.key,
  });

  final RoleVisual visual;
  final UserSession session;
  final int currentIndex;
  final List<NavigationDestination> destinations;
  final List<Widget> children;
  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.lg,
            AppSizes.md,
            AppSizes.lg,
            AppSizes.xl,
          ),
          children: [
            _GreetingHeader(
              session: session,
              visual: visual,
              onLogout: () =>
                  ref.read(authControllerProvider.notifier).logout(),
            ),
            const SizedBox(height: AppSizes.lg),
            ...children,
          ],
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarTheme.of(context).copyWith(
          indicatorColor: visual.soft,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 10,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w600,
              color: states.contains(WidgetState.selected)
                  ? visual.accent
                  : AppColors.muted,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? visual.accent
                  : AppColors.muted,
              size: 20,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
        ),
      ),
    );
  }
}

class SummaryPanel extends StatelessWidget {
  const SummaryPanel({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.metrics,
    super.key,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final List<DashboardMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radius),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 300 && metrics.length > 2) {
                  final firstRow = metrics.take(2).toList();
                  final secondRow = metrics.skip(2).toList();
                  return Column(
                    children: [
                      _buildMetricRow(firstRow, showDividers: true),
                      const Divider(height: AppSizes.lg),
                      _buildMetricRow(secondRow, showDividers: true),
                    ],
                  );
                }
                return _buildMetricRow(metrics, showDividers: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    List<DashboardMetric> items, {
    required bool showDividers,
  }) {
    return Row(
      children: [
        for (final metric in items) ...[
          Expanded(
            child: _SummaryMetric(metric: metric, accent: accent),
          ),
          if (showDividers && metric != items.last)
            const SizedBox(
              height: 44,
              child: VerticalDivider(color: AppColors.line),
            ),
        ],
      ],
    );
  }
}

class DashboardMetric {
  const DashboardMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {this.actionLabel, this.onAction, super.key});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({
    required this.actions,
    required this.accent,
    super.key,
  });

  final List<QuickAction> actions;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisExtent: 82,
        crossAxisSpacing: AppSizes.sm,
        mainAxisSpacing: AppSizes.sm,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return _QuickActionTile(action: action, accent: accent);
      },
    );
  }
}

class QuickAction {
  const QuickAction({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
}

class SubmissionTile extends StatelessWidget {
  const SubmissionTile({
    required this.code,
    required this.primary,
    required this.secondary,
    required this.status,
    this.icon = Icons.description_outlined,
    this.onTap,
    super.key,
  });

  final String code;
  final String primary;
  final String secondary;
  final String status;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              _TinyIcon(
                icon: icon,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      primary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      secondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              StatusBadge(status: status),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    required this.label,
    required this.value,
    this.icon,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: AppColors.muted),
          const SizedBox(width: AppSizes.sm),
        ],
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class SearchBarMock extends StatelessWidget {
  const SearchBarMock({
    required this.hint,
    this.trailingIcon,
    this.onTrailingPressed,
    super.key,
  });

  final String hint;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(AppSizes.pill),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: AppColors.muted),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.subtle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: AppSizes.sm),
          IconButton.filledTonal(
            onPressed: onTrailingPressed,
            icon: Icon(trailingIcon, size: 18),
          ),
        ],
      ],
    );
  }
}

class MapPreviewCard extends StatelessWidget {
  const MapPreviewCard({required this.accent, super.key});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        child: SizedBox(
          height: 146,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.12),
                        const Color(0xFFEAF6F0),
                        const Color(0xFFE8F3FF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 24,
                left: 34,
                child: _MapMarker(color: AppColors.warning),
              ),
              Positioned(top: 54, right: 48, child: _MapMarker(color: accent)),
              Positioned(
                bottom: 34,
                left: 126,
                child: _MapMarker(color: AppColors.danger),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: IconButton.filledTonal(
                  onPressed: null,
                  icon: const Icon(Icons.refresh, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MiniReportCard extends StatelessWidget {
  const MiniReportCard({required this.accent, super.key});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    const values = [2.0, 6.0, 5.0, 12.0, 8.0, 15.0, 13.0, 9.0];
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grafik Pengajuan',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: 106,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final value in values) ...[
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 18 + (value / maxValue * 78),
                        width: 10,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(AppSizes.pill),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.session,
    required this.visual,
    required this.onLogout,
  });

  final UserSession session;
  final RoleVisual visual;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: visual.soft,
            borderRadius: BorderRadius.circular(AppSizes.radius),
          ),
          child: Icon(visual.icon, color: visual.accent, size: 24),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selamat datang,',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              Text(
                session.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                session.role.label,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Logout'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.metric, required this.accent});

  final DashboardMetric metric;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final color = metric.color ?? accent;
    return Column(
      children: [
        Icon(metric.icon, color: color, size: 17),
        const SizedBox(height: 5),
        Text(
          metric.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          metric.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action, required this.accent});

  final QuickAction action;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSizes.radius),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: accent, size: 21),
              const SizedBox(height: AppSizes.sm),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TinyIcon extends StatelessWidget {
  const _TinyIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.pill),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(Icons.directions_boat_filled, color: color, size: 17),
    );
  }
}
