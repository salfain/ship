import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final meta = _StatusMeta.fromStatus(status);
    return Container(
      constraints: const BoxConstraints(minHeight: 24, maxWidth: 116),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: meta.color.withValues(alpha: 0.32)),
      ),
      child: Text(
        meta.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: meta.color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusMeta {
  const _StatusMeta(this.label, this.color);

  final String label;
  final Color color;

  static _StatusMeta fromStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const _StatusMeta('Menunggu Verifikasi', AppColors.warning);
      case 'WAITING_MANAGER_VALIDATION':
        return const _StatusMeta('Menunggu Keputusan', AppColors.info);
      case 'APPROVED':
        return const _StatusMeta('Disetujui', AppColors.success);
      case 'REJECTED':
        return const _StatusMeta('Ditolak', AppColors.danger);
      default:
        return _StatusMeta(
          status.isEmpty ? 'Belum Ada Status' : status,
          AppColors.muted,
        );
    }
  }
}
