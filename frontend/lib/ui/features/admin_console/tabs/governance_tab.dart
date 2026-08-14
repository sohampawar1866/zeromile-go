// lib/ui/features/admin_console/tabs/governance_tab.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../logic/view_models/superadmin_view_model.dart';
import '../../../core/widgets/fluid_tap_scale.dart';
import '../../../core/widgets/sos_triage_card.dart';
import '../../../core/dialogs/publish_broadcast_modal.dart';

class GovernanceTab extends StatelessWidget {
  final SuperAdminViewModel viewModel;
  final String domainId;
  final String adminUserId;

  const GovernanceTab({
    super.key,
    required this.viewModel,
    required this.domainId,
    required this.adminUserId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.edgeInsetsScreen,
      children: [
        // Escalated & Direct SOS Queue
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
                              'Escalated Response Queue',
                              style: AppTypography.headingMd,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${viewModel.escalatedSosQueue.length} Active',
                      style: AppTypography.captionXs.copyWith(color: AppColors.sale, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'High-priority incidents forwarded by Group Leaders or submitted by General riders:',
                  style: AppTypography.bodySm,
                ),
                const SizedBox(height: AppSpacing.md),
                if (viewModel.escalatedSosQueue.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                      border: Border.all(color: AppColors.hairlineSoft),
                    ),
                    child: Text(
                      '✓ No active emergency incidents in queue.',
                      style: AppTypography.bodySm.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  ...viewModel.escalatedSosQueue.map((sos) => SosTriageCard(
                    event: sos,
                    isSuperAdmin: true,
                    onResolve: () async {
                      final ok = await viewModel.resolveSosIncident(
                        sosId: sos.id,
                        adminUserId: adminUserId,
                      );
                      if (context.mounted && ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ambulance dispatched & incident resolved.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                  )),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Broadcast Trigger (Black Pill Button)
        FluidTapScale(
          onTap: () {
            PublishBroadcastModal.show(
              context,
              isSuperAdmin: true,
              onPublish: (text, _) async {
                final ok = await viewModel.sendDomainBroadcast(
                  domainId: domainId,
                  adminUserId: adminUserId,
                  messageText: text,
                );
                if (context.mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Domain-wide alert dispatched to all subscribers.'),
                      backgroundColor: AppColors.sale,
                    ),
                  );
                }
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.sale,
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
            ),
            alignment: Alignment.center,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign, size: 18, color: AppColors.onPrimary),
                SizedBox(width: AppSpacing.sm),
                Text('Publish Domain-Wide Broadcast Alert', style: AppTypography.buttonMd),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Pending Group Creation Applications
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Contingent Proposals (${viewModel.pendingRequests.length})',
                  style: AppTypography.headingMd,
                ),
                const SizedBox(height: AppSpacing.md),
                if (viewModel.pendingRequests.isEmpty)
                  const Text('No pending group proposals to review.', style: AppTypography.caption)
                else
                  ...viewModel.pendingRequests.map((req) => Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: AppSpacing.edgeInsetsCard,
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                      border: Border.all(color: AppColors.hairlineSoft),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(req.orgName, style: AppTypography.headingMd),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Category: ${req.orgType} • Expected: ${req.expectedCount} Riders • Muster: ${req.musterPoint}',
                          style: AppTypography.caption,
                        ),
                        if (req.leaderNotes != null && req.leaderNotes!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text('Remarks: ${req.leaderNotes}', style: AppTypography.bodySm.copyWith(color: AppColors.warningBright)),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: FluidTapScale(
                                onTap: () async {
                                  final ok = await viewModel.reviewGroupProposal(
                                    requestId: req.id,
                                    reviewerUserId: adminUserId,
                                    approve: true,
                                  );
                                  if (context.mounted && ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Approved! Sub-group created & applicant elevated to Leader.'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                  decoration: const BoxDecoration(
                                    color: AppColors.ink,
                                    borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('✓ Approve', style: AppTypography.buttonSm),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: FluidTapScale(
                                onTap: () async {
                                  final ok = await viewModel.reviewGroupProposal(
                                    requestId: req.id,
                                    reviewerUserId: adminUserId,
                                    approve: false,
                                  );
                                  if (context.mounted && ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Proposal rejected.')),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: AppColors.softCloud,
                                    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
                                    border: Border.all(color: AppColors.hairline),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('✗ Reject', style: AppTypography.buttonSm.copyWith(color: AppColors.ink)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
