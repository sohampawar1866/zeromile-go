// lib/ui/core/components/shad_card.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';

/// Structured Card component following modern Shadcn UI layout paradigms:
/// Header (Title, Subtitle, Trailing Action) -> Content (Child) -> Footer (Actions)
class ShadCard extends StatelessWidget {
  final Widget? header;
  final String? title;
  final String? description;
  final Widget? trailing;
  final Widget child;
  final Widget? footer;
  final EdgeInsetsGeometry padding;

  const ShadCard({
    super.key,
    this.header,
    this.title,
    this.description,
    this.trailing,
    required this.child,
    this.footer,
    this.padding = AppSpacing.edgeInsetsCard,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : AppColors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : AppColors.hairline,
          width: 1.0,
        ),
        boxShadow: isDark
            ? []
            : const [
                BoxShadow(
                  color: Color(0x08000000),
                  offset: Offset(0, 1),
                  blurRadius: 3,
                  spreadRadius: 0,
                ),
              ],
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null) ...[
            header!,
            const SizedBox(height: AppSpacing.sm),
          ] else if (title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: AppTypography.headingMd.copyWith(
                          color: isDark ? const Color(0xFFF4F4F5) : AppColors.ink,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (description != null) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          description!,
                          style: AppTypography.caption.copyWith(
                            color: isDark ? const Color(0xFFA1A1AA) : AppColors.mute,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          child,
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.md),
            footer!,
          ],
        ],
      ),
    );
  }
}
