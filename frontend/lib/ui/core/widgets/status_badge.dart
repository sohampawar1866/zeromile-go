// lib/ui/core/widgets/status_badge.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';

enum StatusBadgeType { primary, success, warning, error, muted }

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    switch (type) {
      case StatusBadgeType.primary:
        bg = AppColors.ink;
        fg = AppColors.onPrimary;
        border = AppColors.ink;
        break;
      case StatusBadgeType.success:
        bg = AppColors.successBg;
        fg = AppColors.success;
        border = AppColors.successBorder;
        break;
      case StatusBadgeType.warning:
        bg = AppColors.warningBg;
        fg = AppColors.warningAccent;
        border = AppColors.warningBorder;
        break;
      case StatusBadgeType.error:
        bg = AppColors.errorBg;
        fg = AppColors.sale;
        border = AppColors.errorBorder;
        break;
      case StatusBadgeType.muted:
        bg = AppColors.softCloud;
        fg = AppColors.mute;
        border = AppColors.hairline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs + 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: AppSpacing.xxs + 1),
          ],
          Text(
            label,
            style: AppTypography.badge.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
