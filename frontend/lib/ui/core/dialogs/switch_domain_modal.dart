// lib/ui/core/dialogs/switch_domain_modal.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../models/event_domain.dart';
import '../widgets/status_badge.dart';

class SwitchDomainModal extends StatelessWidget {
  final EventDomain? currentDomain;
  final List<EventDomain> domains;
  final ValueChanged<EventDomain> onSelectDomain;

  const SwitchDomainModal({
    super.key,
    required this.currentDomain,
    required this.domains,
    required this.onSelectDomain,
  });

  static Future<void> show(
    BuildContext context, {
    required EventDomain? currentDomain,
    required List<EventDomain> domains,
    required ValueChanged<EventDomain> onSelectDomain,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SwitchDomainModal(
        currentDomain: currentDomain,
        domains: domains,
        onSelectDomain: onSelectDomain,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('SWITCH ACTIVE RALLY DOMAIN', style: AppTypography.headingLg),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Switch between different municipal rallies and event campaigns in Nagpur:',
              style: AppTypography.bodySm,
            ),
            const SizedBox(height: AppSpacing.md),
            if (domains.isEmpty)
              const Text('No alternate domains available.', style: AppTypography.caption)
            else
              ...domains.map((dom) {
                final isSelected = currentDomain?.id == dom.id;
                final isLive = dom.status == EventDomainStatus.liveActive;

                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onSelectDomain(dom);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: AppSpacing.edgeInsetsCard,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.softCloud : AppColors.canvas,
                      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                      border: Border.all(
                        color: isSelected ? AppColors.ink : AppColors.hairlineSoft,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getDomainIcon(dom.type),
                          color: isSelected ? AppColors.ink : AppColors.mute,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dom.name,
                                style: AppTypography.bodyStrong.copyWith(
                                  color: isSelected ? AppColors.ink : AppColors.charcoal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                '${dom.type.name.toUpperCase()} • ${dom.startTime.day}/${dom.startTime.month}/${dom.startTime.year}',
                                style: AppTypography.caption,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: isLive ? 'LIVE' : 'UPCOMING',
                          type: isLive ? StatusBadgeType.success : StatusBadgeType.muted,
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  IconData _getDomainIcon(EventDomainType type) {
    switch (type) {
      case EventDomainType.cycling:
        return Icons.directions_bike;
      case EventDomainType.marathon:
        return Icons.directions_run;
      case EventDomainType.walkathon:
        return Icons.directions_walk;
      case EventDomainType.protest:
        return Icons.campaign;
      case EventDomainType.other:
        return Icons.event;
    }
  }
}
