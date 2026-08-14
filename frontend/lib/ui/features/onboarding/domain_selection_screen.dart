// lib/ui/features/onboarding/domain_selection_screen.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../models/event_domain.dart';
import '../../../main.dart';
import '../../core/widgets/status_badge.dart';

class DomainSelectionScreen extends StatefulWidget {
  final List<EventDomain>? domains;
  final ValueChanged<EventDomain>? onDomainSelected;

  const DomainSelectionScreen({
    super.key,
    this.domains,
    this.onDomainSelected,
  });

  @override
  State<DomainSelectionScreen> createState() => _DomainSelectionScreenState();
}

class _DomainSelectionScreenState extends State<DomainSelectionScreen> {
  late final List<EventDomain> _domains;

  @override
  void initState() {
    super.initState();
    _domains = widget.domains != null && widget.domains!.isNotEmpty
        ? widget.domains!
        : [
            EventDomain(
              id: 'cycling-2026',
              name: 'Nagpur Heritage Cycling Rally 2026',
              slug: 'cycling-2026',
              type: EventDomainType.cycling,
              status: EventDomainStatus.liveActive,
              startTime: DateTime(2026, 8, 15, 6, 0),
              endTime: DateTime(2026, 8, 15, 10, 30),
              createdAt: DateTime.now(),
            ),
            EventDomain(
              id: 'marathon-2026',
              name: 'Nagpur City Half-Marathon 2026',
              slug: 'marathon-2026',
              type: EventDomainType.marathon,
              status: EventDomainStatus.upcoming,
              startTime: DateTime(2026, 9, 20, 5, 30),
              endTime: DateTime(2026, 9, 20, 11, 0),
              createdAt: DateTime.now(),
            ),
            EventDomain(
              id: 'protest-rally-2026',
              name: 'Nagpur Citizen Peace Procession',
              slug: 'peace-protest-2026',
              type: EventDomainType.protest,
              status: EventDomainStatus.upcoming,
              startTime: DateTime(2026, 10, 2, 8, 0),
              endTime: DateTime(2026, 10, 2, 14, 0),
              createdAt: DateTime.now(),
            ),
          ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Select Rally Domain'),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.edgeInsetsScreen,
          children: [
            const Text(
              'OFFICIAL EVENT CAMPAIGNS',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Select an active municipal event domain to access route telemetry, live density heatmaps, and contingent coordination:',
              style: AppTypography.bodySm,
            ),
            const SizedBox(height: AppSpacing.lg),
            ..._domains.map((dom) {
              final isLive = dom.status == EventDomainStatus.liveActive;

              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Card(
                  child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                    onTap: () {
                      if (widget.onDomainSelected != null) {
                        widget.onDomainSelected!(dom);
                      } else {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const ZeroMileGoApp()),
                          (route) => false,
                        );
                      }
                    },
                    child: Padding(
                      padding: AppSpacing.edgeInsetsCard,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: isLive ? AppColors.ink : AppColors.softCloud,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getDomainIcon(dom.type),
                                  color: isLive ? AppColors.onPrimary : AppColors.ink,
                                  size: 20,
                                ),
                              ),
                              StatusBadge(
                                label: isLive ? 'LIVE ACTIVE' : 'UPCOMING',
                                type: isLive ? StatusBadgeType.success : StatusBadgeType.muted,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            dom.name,
                            style: AppTypography.headingMd,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${dom.type.name.toUpperCase()} • ${dom.startTime.day}/${dom.startTime.month}/${dom.startTime.year} • 06:00 AM - 10:30 AM',
                            style: AppTypography.caption,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
                            decoration: BoxDecoration(
                              color: isLive ? AppColors.ink : AppColors.softCloud,
                              borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
                              border: isLive ? null : Border.all(color: AppColors.hairline),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLive ? 'ENTER EVENT DASHBOARD' : 'VIEW SCHEDULE & DETAILS',
                                  style: AppTypography.buttonSm.copyWith(
                                    color: isLive ? AppColors.onPrimary : AppColors.ink,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 14,
                                  color: isLive ? AppColors.onPrimary : AppColors.ink,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
