// lib/ui/core/components/shad_button.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../widgets/fluid_tap_scale.dart';

enum ShadButtonVariant { primary, secondary, outline, ghost, destructive, success }
enum ShadButtonSize { sm, md, lg }

/// Reusable atomic button adhering to Shadcn UI design patterns
/// Guaranteed overflow-safe on ultra-narrow mobile viewports.
class ShadButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ShadButtonVariant variant;
  final ShadButtonSize size;
  final bool isLoading;
  final bool isFullWidth;

  const ShadButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.variant = ShadButtonVariant.primary,
    this.size = ShadButtonSize.md,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (bgColor, fgColor, border) = switch (variant) {
      ShadButtonVariant.primary => isDark
          ? (const Color(0xFFF4F4F5), const Color(0xFF09090B), null)
          : (AppColors.ink, AppColors.onPrimary, null),
      ShadButtonVariant.secondary => isDark
          ? (const Color(0xFF27272A), const Color(0xFFF4F4F5), Border.all(color: const Color(0xFF3F3F46)))
          : (AppColors.softCloud, AppColors.ink, Border.all(color: AppColors.hairline)),
      ShadButtonVariant.outline => isDark
          ? (Colors.transparent, const Color(0xFFF4F4F5), Border.all(color: const Color(0xFF3F3F46)))
          : (AppColors.surface, AppColors.ink, Border.all(color: AppColors.borderLight)),
      ShadButtonVariant.ghost => (Colors.transparent, isDark ? const Color(0xFFF4F4F5) : AppColors.ink, null),
      ShadButtonVariant.destructive => (AppColors.sale, AppColors.onPrimary, null),
      ShadButtonVariant.success => (AppColors.success, AppColors.onPrimary, null),
    };

    final (padding, textStyle, iconSize) = switch (size) {
      ShadButtonSize.sm => (
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          AppTypography.buttonSm,
          14.0,
        ),
      ShadButtonSize.md => (
          const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          AppTypography.buttonMd,
          16.0,
        ),
      ShadButtonSize.lg => (
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          AppTypography.buttonLg,
          18.0,
        ),
    };

    final isDisabled = onPressed == null || isLoading;

    return FluidTapScale(
      onTap: isDisabled ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: isFullWidth ? double.infinity : null,
        padding: padding,
        decoration: BoxDecoration(
          color: isDisabled
              ? (isDark ? const Color(0xFF27272A) : AppColors.buttonDisabledBg)
              : bgColor,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
          border: border,
          boxShadow: (!isDisabled && variant == ShadButtonVariant.primary && !isDark)
              ? const [
                  BoxShadow(
                    color: Color(0x140F172A),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                ),
              ),
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: iconSize,
                color: isDisabled
                    ? (isDark ? const Color(0xFF71717A) : AppColors.buttonDisabledText)
                    : fgColor,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              fit: isFullWidth ? FlexFit.loose : FlexFit.loose,
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textStyle.copyWith(
                  color: isDisabled
                      ? (isDark ? const Color(0xFF71717A) : AppColors.buttonDisabledText)
                      : fgColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
