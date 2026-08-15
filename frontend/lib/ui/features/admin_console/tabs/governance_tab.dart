// lib/ui/features/admin_console/tabs/governance_tab.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../logic/view_models/superadmin_view_model.dart';
import '../../../core/widgets/sos_triage_card.dart';
import '../../../core/dialogs/publish_broadcast_modal.dart';
import '../../../core/components/shad_button.dart';
import '../../../core/components/shad_card.dart';

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
    final activeQueueCount = viewModel.escalatedSosQueue.length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      children: [
        // 1. Escalated & Direct SOS Queue
        ShadCard(
          title: 'Escalated SOS Queue',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: activeQueueCount > 0 ? AppColors.errorBg : AppColors.successBg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: activeQueueCount > 0 ? AppColors.errorBorder : AppColors.successBorder,
              ),
            ),
            child: Text(
              activeQueueCount > 0 ? '$activeQueueCount ACTIVE' : '0 ACTIVE',
              style: AppTypography.captionXs.copyWith(
                color: activeQueueCount > 0 ? AppColors.sale : AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (viewModel.escalatedSosQueue.isEmpty)
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
                          'No escalated emergency incidents in queue.',
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
                          content: Text('Incident resolved & ambulances notified.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                )),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // 2. City Broadcast & Alert Actions
        ShadCard(
          title: 'Event Operations & Safety Alert',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Broadcast critical instructions to all registered riders and contingent leaders simultaneously:',
                style: AppTypography.bodySm,
              ),
              const SizedBox(height: AppSpacing.md),
              ShadButton(
                text: 'Publish Citywide Broadcast',
                icon: Icons.campaign_outlined,
                isFullWidth: true,
                variant: ShadButtonVariant.destructive,
                onPressed: () {
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
                            content: Text('Domain broadcast published.'),
                            backgroundColor: AppColors.ink,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // 3. Pending Contingent Approvals
        ShadCard(
          title: 'Squad & Club Approvals',
          trailing: Text(
            '${viewModel.pendingRequests.length} Pending',
            style: AppTypography.captionXs.copyWith(color: AppColors.mute),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (viewModel.pendingRequests.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                    border: Border.all(color: AppColors.hairlineSoft),
                  ),
                  child: const Text(
                    'No pending contingent approval requests.',
                    style: AppTypography.caption,
                  ),
                )
              else
                ...viewModel.pendingRequests.map((req) {
                  final groupName = req.orgName;
                  final requestId = req.id;
                  final orgType = req.orgType;

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.hairlineSoft),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(groupName, style: AppTypography.bodyStrong),
                              const SizedBox(height: 2),
                              Text('Type: $orgType', style: AppTypography.caption),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            ShadButton(
                              text: 'Approve',
                              size: ShadButtonSize.sm,
                              variant: ShadButtonVariant.primary,
                              onPressed: () async {
                                final ok = await viewModel.reviewGroupProposal(
                                  requestId: requestId,
                                  reviewerUserId: adminUserId,
                                  approve: true,
                                );
                                if (context.mounted && ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Approved $groupName contingent.'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),

        const SizedBox(height: 88),
      ],
    );
  }
}
