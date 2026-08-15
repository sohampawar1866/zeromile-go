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

    return ListView(
      padding: AppSpacing.edgeInsetsScreen,
      children: [
        // Squad Readiness & Muster Summary
        ShadCard(
          title: viewModel.groupName,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.liveIndicatorBg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sensors, size: 12, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  '${viewModel.activeToday} Live',
                  style: AppTypography.captionXs.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meeting Point: ${viewModel.musterPoint}',
                style: AppTypography.bodySm,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _buildMiniStat('Members', '${viewModel.totalEnrolled}'),
                  const SizedBox(width: AppSpacing.sm),
                  _buildMiniStat('Checked-In', '${viewModel.checkedInCount} (${viewModel.checkinPercent.toStringAsFixed(0)}%)'),
                  const SizedBox(width: AppSpacing.sm),
                  _buildMiniStat('Finished', '${viewModel.completedCount}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Priority SOS Triage Queue
        ShadCard(
          title: 'Team Emergency & Help Alerts',
          trailing: Text(
            activeSosCount > 0 ? '$activeSosCount Active' : '0 Active',
            style: AppTypography.captionXs.copyWith(
              color: activeSosCount > 0 ? AppColors.sale : AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (viewModel.teamSosAlerts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                    border: Border.all(color: AppColors.hairlineSoft),
                  ),
                  child: Text(
                    '✓ All team riders safe. No active emergency pings.',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
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
                              const SizedBox(height: 12),
                              const Text(
                                'Connecting to mobile cellular dialer with highest priority.',
                                style: AppTypography.caption,
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

        // Live Squad GPS Telemetry Map HUD
        ShadCard(
          title: 'Live Team GPS Tracking',
          trailing: Text(
            '${viewModel.teamLocations.length} Online',
            style: AppTypography.captionXs.copyWith(color: AppColors.mute),
          ),
          child: DensityClusterMapView(
            title: '${viewModel.groupName} Live Map',
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Quick Actions
        Row(
          children: [
            Expanded(
              child: ShadButton(
                text: 'Add Rider to Team',
                icon: Icons.person_add,
                variant: ShadButtonVariant.primary,
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
                text: 'Send Team Notice',
                icon: Icons.campaign,
                variant: ShadButtonVariant.secondary,
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

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.hairlineSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.captionXs),
            const SizedBox(height: 2),
            Text(value, style: AppTypography.bodyStrong),
          ],
        ),
      ),
    );
  }
}
