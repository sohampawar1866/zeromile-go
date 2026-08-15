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
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.primary,
    this.icon,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;
    Color dotColor;

    switch (type) {
      case StatusBadgeType.primary:
        bg = AppColors.primaryLight;
        fg = AppColors.onPrimary;
        border = AppColors.primary;
        dotColor = AppColors.white;
        break;
      case StatusBadgeType.success:
        bg = AppColors.successBg;
        fg = AppColors.success;
        border = AppColors.successBorder;
        dotColor = AppColors.success;
        break;
      case StatusBadgeType.warning:
        bg = AppColors.warningBg;
        fg = AppColors.warningAccent;
        border = AppColors.warningBorder;
        dotColor = AppColors.warning;
        break;
      case StatusBadgeType.error:
        bg = AppColors.errorBg;
        fg = AppColors.sale;
        border = AppColors.errorBorder;
        dotColor = AppColors.sale;
        break;
      case StatusBadgeType.muted:
        bg = AppColors.softCloud;
        fg = AppColors.textSecondary;
        border = AppColors.hairline;
        dotColor = AppColors.mute;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ] else if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              style: AppTypography.badge.copyWith(color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
