// lib/ui/features/leader_hub/tabs/team_hub_tab.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../models/group_membership.dart';
import '../../../../logic/view_models/leader_hub_view_model.dart';
import '../../../core/widgets/fluid_tap_scale.dart';
import '../../../core/widgets/sos_triage_card.dart';
import '../../../core/dialogs/direct_add_member_modal.dart';
import '../../../core/dialogs/publish_broadcast_modal.dart';

class TeamHubTab extends StatelessWidget {
  final LeaderHubViewModel viewModel;
  final String domainId;
  final String groupId;
  final String leaderUserId;

  const TeamHubTab({
    super.key,
    required this.viewModel,
    required this.domainId,
    required this.groupId,
    required this.leaderUserId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.edgeInsetsScreen,
      children: [
        // Team SOS Triage Queue Card
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppColors.sale, size: 20),
                          SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Team SOS Triage Queue',
                              style: AppTypography.headingMd,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${viewModel.teamSosAlerts.length} Active',
                      style: AppTypography.captionXs.copyWith(color: AppColors.sale, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Distress pings from your active contingent. Resolve locally or forward to SuperAdmins:',
                  style: AppTypography.bodySm,
                ),
                const SizedBox(height: AppSpacing.md),
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
                      '✓ No active emergencies in your contingent.',
                      style: AppTypography.bodySm.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  ...viewModel.teamSosAlerts.map((sos) => SosTriageCard(
                    event: sos,
                    isSuperAdmin: false,
                    onCall: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling ${sos.senderPhone ?? "member"}...')),
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
                          const SnackBar(content: Text('Incident resolved locally.'), backgroundColor: AppColors.success),
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
                          const SnackBar(content: Text('Alert forwarded to Domain SuperAdmins.'), backgroundColor: AppColors.warning),
                        );
                      }
                    },
                  )),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Quick Actions (Nike Black & Soft Cloud Pills)
        Row(
          children: [
            Expanded(
              child: FluidTapScale(
                onTap: () {
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
                          SnackBar(content: Text('Added $name directly to roster.'), backgroundColor: AppColors.success),
                        );
                      }
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add, size: 15, color: AppColors.onPrimary),
                      SizedBox(width: AppSpacing.xs),
                      Text('Add Member', style: AppTypography.buttonSm),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FluidTapScale(
                onTap: () {
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
                          const SnackBar(content: Text('Team announcement sent.'), backgroundColor: AppColors.ink),
                        );
                      }
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.softCloud,
                    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.campaign, size: 15, color: AppColors.ink),
                      const SizedBox(width: AppSpacing.xs),
                      Text('Broadcast', style: AppTypography.buttonSm.copyWith(color: AppColors.ink)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Team Member Roster
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Team Muster Roster (${viewModel.roster.length})',
                        style: AppTypography.headingMd,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${viewModel.checkedInMuster} Checked-in',
                      style: AppTypography.captionXs.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (viewModel.roster.isEmpty)
                  const Text('No members in contingent yet.', style: AppTypography.caption)
                else
                  ...viewModel.roster.map((m) {
                    final isChecked = m.participationStatus == ParticipationStatus.checkedIn;
                    final isComplete = m.participationStatus == ParticipationStatus.completed;

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: AppSpacing.edgeInsetsCard,
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                        border: Border.all(color: AppColors.hairlineSoft),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isComplete ? Icons.flag : isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isComplete ? AppColors.ink : isChecked ? AppColors.success : AppColors.mute,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${m.userFullName ?? "Rider"} ${m.isLeader ? "(Leader)" : ""}',
                                  style: AppTypography.bodyStrong,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  '${m.userPhoneNumber ?? "+91 98XXX"} • ${m.participationStatus.name.toUpperCase()}',
                                  style: AppTypography.caption,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
