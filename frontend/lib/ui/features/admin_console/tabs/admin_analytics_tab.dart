// lib/ui/features/admin_console/tabs/admin_analytics_tab.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../logic/view_models/superadmin_view_model.dart';
import '../../../core/widgets/fluid_tap_scale.dart';

class AdminAnalyticsTab extends StatelessWidget {
  final SuperAdminViewModel viewModel;

  const AdminAnalyticsTab({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final totalGroups = viewModel.subGroups.isNotEmpty ? viewModel.subGroups.length : 1;
    final collegeCount = viewModel.subGroups.where((g) => g.orgType == 'COLLEGE').length;
    final sportsCount = viewModel.subGroups.where((g) => g.orgType == 'SPORTS_CLUB').length;
    final generalCount = viewModel.subGroups.where((g) => g.orgType == 'GENERAL' || g.orgType == 'NGO' || g.orgType == 'RWA').length;

    final collegeFraction = totalGroups > 0 ? (collegeCount / totalGroups).clamp(0.0, 1.0) : 0.0;
    final sportsFraction = totalGroups > 0 ? (sportsCount / totalGroups).clamp(0.0, 1.0) : 0.0;
    final generalFraction = totalGroups > 0 ? (generalCount / totalGroups).clamp(0.0, 1.0) : 0.0;

    return ListView(
      padding: AppSpacing.edgeInsetsScreen,
      children: [
        // Participation Summary Card
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Event Participation Overview', style: AppTypography.headingMd),
                const SizedBox(height: AppSpacing.md),
                _buildStatItem('Riders Live on Route', '${viewModel.activeRiderCount} Participants'),
                _buildStatItem('Registered Groups & Clubs', '${viewModel.subGroups.length} Groups'),
                _buildStatItem('Pending Group Requests', '${viewModel.pendingRequests.length} Pending Review'),
                _buildStatItem('Active SOS Emergency Queue', '${viewModel.escalatedSosQueue.length} Active Tickets'),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Route Traffic & Incident SLA Card
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Route Traffic & Safety Incident SLA', style: AppTypography.headingMd),
                const SizedBox(height: AppSpacing.md),
                _buildStatItem('Active Emergency Dispatches', '${viewModel.escalatedSosQueue.length} Dispatched'),
                _buildStatItem('Active Groups Enrolled', '${viewModel.subGroups.length} Groups'),
                _buildStatItem('Active Group Filter Target', viewModel.selectedGroupFilter.isEmpty ? 'All Event Groups' : 'Selected Group'),
                _buildStatItem('Live GPS Connection', 'Connected (Supabase Realtime)'),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Contingent Breakdown by Org Type
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Group Breakdown (By Category)', style: AppTypography.headingMd),
                const SizedBox(height: AppSpacing.md),
                _buildBreakdownBar('Educational / Colleges (VNIT, etc.)', collegeFraction, '$collegeCount Groups (${(collegeFraction * 100).toStringAsFixed(0)}%)', AppColors.ink),
                _buildBreakdownBar('Sports & Athletic Clubs', sportsFraction, '$sportsCount Groups (${(sportsFraction * 100).toStringAsFixed(0)}%)', AppColors.info),
                _buildBreakdownBar('General & Civil Society Orgs', generalFraction, '$generalCount Groups (${(generalFraction * 100).toStringAsFixed(0)}%)', AppColors.accentTeal),
                const SizedBox(height: AppSpacing.md),

                SizedBox(
                  width: double.infinity,
                  child: FluidTapScale(
                    onTap: () {
                      final auditCsv = StringBuffer();
                      auditCsv.writeln('ZeroMile Go Domain Audit Log Report');
                      auditCsv.writeln('Generated At,${DateTime.now().toIso8601String()}');
                      auditCsv.writeln('Active GPS Telemetry Online,${viewModel.activeRiderCount}');
                      auditCsv.writeln('Approved Sub-Groups,${viewModel.subGroups.length}');
                      auditCsv.writeln('Active SOS Emergency Queue,${viewModel.escalatedSosQueue.length}');
                      auditCsv.writeln('\n--- SUB-GROUP BREAKDOWN ---');
                      auditCsv.writeln('Group Name,Org Type,Muster Point,Approval Status');
                      for (final g in viewModel.subGroups) {
                        auditCsv.writeln('"${g.name}","${g.orgType}","${g.musterPoint ?? "Standard Flag-off"}","${g.approvalStatus.name.toUpperCase()}"');
                      }

                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(Icons.file_download_done, color: AppColors.success, size: 20),
                              SizedBox(width: 8),
                              Text('Domain Audit Log Export', style: AppTypography.headingMd),
                            ],
                          ),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Domain audit log CSV generated successfully. Ready for dissemination to municipal authorities and emergency response team:',
                                  style: AppTypography.bodySm,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.softCloud,
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(color: AppColors.hairlineSoft),
                                  ),
                                  child: SelectableText(
                                    auditCsv.toString(),
                                    style: const TextStyle(fontFamily: 'Courier', fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Done', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
                        border: Border.all(color: AppColors.hairline),
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download, size: 16, color: AppColors.ink),
                          SizedBox(width: AppSpacing.sm),
                          Text('Download Domain Audit Log', style: AppTypography.buttonSmSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodySm),
          const SizedBox(height: 3),
          Text(value, style: AppTypography.bodyStrong),
        ],
      ),
    );
  }

  Widget _buildBreakdownBar(String label, double fraction, String countStr, Color barColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: AppTypography.bodyStrong, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: AppSpacing.xs),
              Text(countStr, style: AppTypography.captionXs.copyWith(color: barColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
            backgroundColor: AppColors.hairlineSoft,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ],
      ),
    );
  }
}
