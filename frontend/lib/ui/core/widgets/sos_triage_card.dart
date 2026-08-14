// lib/ui/core/widgets/sos_triage_card.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../data/models/sos_event.dart';
import 'fluid_tap_scale.dart';
import 'status_badge.dart';

class SosTriageCard extends StatelessWidget {
  final SosEvent event;
  final bool isSuperAdmin;
  final VoidCallback? onCall;
  final VoidCallback? onResolve;
  final VoidCallback? onForward;

  const SosTriageCard({
    super.key,
    required this.event,
    this.isSuperAdmin = false,
    this.onCall,
    this.onResolve,
    this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    final typeName = event.emergencyType.name.toUpperCase();
    final timeStr = '${event.createdAt.hour}:${event.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.edgeInsetsCard,
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        border: Border.all(color: AppColors.errorBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.emergency_outlined, size: 16, color: AppColors.sale),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '🚨 $typeName DISTRESS',
                        style: AppTypography.headingMd.copyWith(color: AppColors.sale),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              StatusBadge(
                label: timeStr,
                type: StatusBadgeType.error,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${event.senderName ?? "Participant"} (${event.senderPhone ?? "+91 98XXX"})',
            style: AppTypography.bodyStrong.copyWith(color: AppColors.saleDeep),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Contingent: ${event.groupName ?? "General Rider"} • GPS: ${event.latitude.toStringAsFixed(4)}, ${event.longitude.toStringAsFixed(4)}',
            style: AppTypography.captionXs.copyWith(color: AppColors.charcoal),
            overflow: TextOverflow.ellipsis,
          ),
          if (event.leaderNotes != null && event.leaderNotes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Leader Note: ${event.leaderNotes}',
              style: AppTypography.captionXs.copyWith(
                color: AppColors.saleDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (onCall != null) ...[
                Expanded(
                  child: FluidTapScale(
                    onTap: onCall!,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
                        border: Border.all(color: AppColors.hairline),
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.call, size: 13, color: AppColors.ink),
                          SizedBox(width: AppSpacing.xxs),
                          Text('Call', style: AppTypography.buttonSm),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              if (onResolve != null) ...[
                Expanded(
                  child: FluidTapScale(
                    onTap: onResolve!,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      decoration: const BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isSuperAdmin ? 'Dispatch & Resolve' : 'Resolve Locally',
                        style: AppTypography.buttonSm,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
              if (onForward != null && !isSuperAdmin) ...[
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: FluidTapScale(
                    onTap: onForward!,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      decoration: const BoxDecoration(
                        color: AppColors.sale,
                        borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Escalate',
                        style: AppTypography.buttonSm,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
