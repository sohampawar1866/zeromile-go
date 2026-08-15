// lib/ui/features/leader_hub/tabs/team_hub_tab.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../logic/view_models/leader_hub_view_model.dart';
import '../../../core/widgets/sos_triage_card.dart';
import '../../../core/widgets/density_cluster_map_view.dart';
import '../../../core/dialogs/direct_add_member_modal.dart';
import '../../../core/dialogs/publish_broadcast_modal.dart';
import '../../../core/components/shad_button.dart';
import '../../../core/components/shad_card.dart';

class TeamHubTab extends StatelessWidget {
  final LeaderHubViewModel viewModel;
  final String domainId;
  final String groupId;
  final String leaderUserId;
  final VoidCallback? onNavigateToRoster;

  const TeamHubTab({
    super.key,
    required this.viewModel,
    required this.domainId,
    required this.groupId,
    required this.leaderUserId,
    this.onNavigateToRoster,
  });

  @override
  Widget build(BuildContext context) {
    final activeSosCount = viewModel.teamSosAlerts.length;
    final isLive = viewModel.activeToday > 0;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      children: [
        // 1. Hero Team Banner (Matching Participant Style)
        _buildHeroTeamBanner(context, isLive),

        const SizedBox(height: AppSpacing.md),

        // 2. Readiness & Muster Status Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          decoration: BoxDecoration(
            color: isLive ? AppColors.liveIndicatorBg : AppColors.surface,
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
            border: Border.all(
              color: isLive ? AppColors.successBorder : AppColors.hairline,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isLive ? AppColors.success : AppColors.mute,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${viewModel.activeToday} Live • ${viewModel.checkedInCount}/${viewModel.totalEnrolled} Checked-In (${viewModel.checkinPercent.toStringAsFixed(0)}%)',
                  style: AppTypography.captionXs.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isLive ? AppColors.liveIndicatorText : AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                isLive ? Icons.sensors : Icons.schedule,
                color: isLive ? AppColors.success : AppColors.mute,
                size: 16,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // 3. Priority SOS Triage Card
        ShadCard(
          title: 'Safety & SOS Alerts',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: activeSosCount > 0 ? AppColors.errorBg : AppColors.successBg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: activeSosCount > 0 ? AppColors.errorBorder : AppColors.successBorder,
              ),
            ),
            child: Text(
              activeSosCount > 0 ? '$activeSosCount ACTIVE' : '0 ACTIVE',
              style: AppTypography.captionXs.copyWith(
                color: activeSosCount > 0 ? AppColors.sale : AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (viewModel.teamSosAlerts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                    border: Border.all(color: AppColors.hairlineSoft),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'All contingent members reporting safe.',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...viewModel.teamSosAlerts.map(
                  (sos) => SosTriageCard(
                    event: sos,
                    isSuperAdmin: false,
                    onCall: () {
                      final phone = sos.senderPhone ?? "+91 98220 99991";
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(Icons.phone_forwarded, color: AppColors.sale, size: 20),
                              SizedBox(width: 8),
                              Text('Emergency Direct Call', style: AppTypography.headingMd),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Initiating direct emergency line to:', style: AppTypography.bodySm),
                              const SizedBox(height: 8),
                              Text(
                                '${sos.senderName ?? "Team Member"}\n$phone',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel', style: TextStyle(color: AppColors.mute)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.sale,
                                foregroundColor: AppColors.onPrimary,
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Dialing $phone...'),
                                    backgroundColor: AppColors.sale,
                                  ),
                                );
                              },
                              child: const Text('Call Now'),
                            ),
                          ],
                        ),
                      );
                    },
                    onResolve: () async {
                      final ok = await viewModel.resolveSosLocally(
                        sosId: sos.id,
                        leaderUserId: leaderUserId,
                        domainId: domainId,
                        groupId: groupId,
                      );
                      if (context.mounted && ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Incident resolved locally.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    onForward: () async {
                      final ok = await viewModel.forwardSosToAdmin(
                        sosId: sos.id,
                        leaderUserId: leaderUserId,
                        leaderNotes: 'Requested medical ambulance escort.',
                        domainId: domainId,
                        groupId: groupId,
                      );
                      if (context.mounted && ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Alert escalated to Event Organizers.'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // 4. Quick Operations & Contingent Actions
        ShadCard(
          title: 'Squad Operations',
          child: Row(
            children: [
              Expanded(
                child: ShadButton(
                  text: 'Add Member',
                  icon: Icons.person_add_outlined,
                  size: ShadButtonSize.sm,
                  variant: ShadButtonVariant.outline,
                  onPressed: () {
                    DirectAddMemberModal.show(
                      context,
                      onAdd: (name, phone) async {
                        final ok = await viewModel.directAddMember(
                          domainId: domainId,
                          groupId: groupId,
                          leaderUserId: leaderUserId,
                          memberPhone: phone,
                          memberName: name,
                        );
                        if (context.mounted && ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added $name to team attendance.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ShadButton(
                  text: 'Send Notice',
                  icon: Icons.campaign_outlined,
                  size: ShadButtonSize.sm,
                  variant: ShadButtonVariant.primary,
                  onPressed: () {
                    PublishBroadcastModal.show(
                      context,
                      isSuperAdmin: false,
                      onPublish: (text, _) async {
                        final ok = await viewModel.sendTeamBroadcast(
                          domainId: domainId,
                          leaderUserId: leaderUserId,
                          groupId: groupId,
                          messageText: text,
                        );
                        if (context.mounted && ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Team notice dispatched.'),
                              backgroundColor: AppColors.ink,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // 5. Live Squad GPS Telemetry Map HUD
        ShadCard(
          title: 'Live Contingent Radar',
          trailing: Text(
            '${viewModel.teamLocations.length} Active',
            style: AppTypography.captionXs.copyWith(color: AppColors.mute),
          ),
          child: DensityClusterMapView(
            title: '${viewModel.groupName} Live Map',
          ),
        ),

        const SizedBox(height: 88),
      ],
    );
  }

  Widget _buildHeroTeamBanner(BuildContext context, bool isLive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle shield icon
          Positioned(
            right: -8,
            bottom: -8,
            child: Icon(
              Icons.shield_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.08),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                viewModel.groupName,
                style: AppTypography.headingLg.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Muster: ${viewModel.musterPoint} • ${viewModel.totalEnrolled} Members',
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: onNavigateToRoster,
                icon: const Icon(Icons.how_to_reg, size: 15, color: Color(0xFF0F172A)),
                label: Text(
                  'Manage Roster (${viewModel.checkedInCount}/${viewModel.totalEnrolled})',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
