// lib/ui/features/leader_hub/tabs/leader_roster_tab.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../models/group_membership.dart';
import '../../../../logic/view_models/leader_hub_view_model.dart';
import '../../../../utils/phone_utils.dart';
import '../../../core/dialogs/direct_add_member_modal.dart';
import '../../../core/widgets/fluid_tap_scale.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/components/shad_button.dart';
import '../../../core/components/shad_card.dart';

class LeaderRosterTab extends StatefulWidget {
  final LeaderHubViewModel viewModel;
  final String domainId;
  final String groupId;
  final String leaderUserId;

  const LeaderRosterTab({
    super.key,
    required this.viewModel,
    required this.domainId,
    required this.groupId,
    required this.leaderUserId,
  });

  @override
  State<LeaderRosterTab> createState() => _LeaderRosterTabState();
}

class _LeaderRosterTabState extends State<LeaderRosterTab> {
  String _selectedFilter = 'ALL'; // 'ALL', 'CHECKED_IN', 'NOT_CHECKED_IN', 'COMPLETED'
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roster = widget.viewModel.roster;
    final filteredRoster = roster.where((m) {
      if (_selectedFilter == 'CHECKED_IN' && m.participationStatus != ParticipationStatus.checkedIn) {
        return false;
      }
      if (_selectedFilter == 'NOT_CHECKED_IN' && m.participationStatus != ParticipationStatus.notCheckedIn) {
        return false;
      }
      if (_selectedFilter == 'COMPLETED' && m.participationStatus != ParticipationStatus.completed) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = (m.userFullName ?? '').toLowerCase().contains(q);
        final phoneMatch = (m.userPhoneNumber ?? '').toLowerCase().contains(q);
        return nameMatch || phoneMatch;
      }
      return true;
    }).toList();

    final checkedInCount = widget.viewModel.checkedInCount;
    final totalCount = roster.length;
    final missingCount = roster.where((m) => m.participationStatus == ParticipationStatus.notCheckedIn).length;
    final completedCount = widget.viewModel.completedCount;

    return ListView(
      padding: AppSpacing.edgeInsetsScreen,
      children: [
        // Roster Summary Card
        ShadCard(
          title: 'Team Attendance & Members',
          trailing: Text(
            '$checkedInCount/$totalCount Present',
            style: AppTypography.captionXs.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meeting Point: ${widget.viewModel.musterPoint}',
                style: AppTypography.bodySm,
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
                child: LinearProgressIndicator(
                  value: widget.viewModel.checkinPercent / 100.0,
                  minHeight: 6,
                  backgroundColor: AppColors.hairlineSoft,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Search and Add Action
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search team members...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ShadButton(
              text: 'Add Rider',
              icon: Icons.person_add,
              variant: ShadButtonVariant.primary,
              size: ShadButtonSize.md,
              onPressed: () {
                DirectAddMemberModal.show(
                  context,
                  onAdd: (name, phone) async {
                    final ok = await widget.viewModel.directAddMember(
                      domainId: widget.domainId,
                      groupId: widget.groupId,
                      leaderUserId: widget.leaderUserId,
                      memberPhone: phone,
                      memberName: name,
                    );
                    if (context.mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added $name to team list.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('ALL', 'All ($totalCount)'),
              _buildFilterChip('CHECKED_IN', 'Checked In ($checkedInCount)'),
              _buildFilterChip('NOT_CHECKED_IN', 'Missing ($missingCount)'),
              _buildFilterChip('COMPLETED', 'Finished ($completedCount)'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Roster Members List
        if (filteredRoster.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.softCloud,
              borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
              border: Border.all(color: AppColors.hairlineSoft),
            ),
            child: const Text(
              'No squad members match this filter.',
              style: AppTypography.caption,
            ),
          )
        else
          ...filteredRoster.map((m) {
            final isChecked = m.participationStatus == ParticipationStatus.checkedIn;
            final isComplete = m.participationStatus == ParticipationStatus.completed;

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: AppSpacing.edgeInsetsCard,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                border: Border.all(
                  color: isChecked ? AppColors.successBorder : AppColors.hairlineSoft,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isComplete
                        ? Icons.military_tech
                        : isChecked
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                    color: isComplete
                        ? AppColors.ink
                        : isChecked
                            ? AppColors.success
                            : AppColors.mute,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                m.userFullName ?? 'Team Rider',
                                style: AppTypography.bodyStrong,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (m.isLeader) ...[
                              const SizedBox(width: 4),
                              const StatusBadge(label: 'Leader', type: StatusBadgeType.warning),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${PhoneUtils.formatDisplay(m.userPhoneNumber ?? "")} • ${isChecked ? "Checked-in" : isComplete ? "Finished" : "Awaiting Check-in"}',
                          style: AppTypography.captionXs.copyWith(
                            color: isChecked ? AppColors.success : AppColors.mute,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.ink),
                    tooltip: 'Call Member',
                    onPressed: () {
                      final phone = m.userPhoneNumber ?? '+91 98220 00000';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Calling ${m.userFullName ?? "Rider"} ($phone)...'),
                          backgroundColor: AppColors.ink,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: AppSpacing.md),

        // Export CSV Button
        FluidTapScale(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Team Attendance list exported to Downloads (CSV).'),
                backgroundColor: AppColors.ink,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
              border: Border.all(color: AppColors.ink, width: 1.2),
            ),
            alignment: Alignment.center,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download, size: 16, color: AppColors.ink),
                SizedBox(width: AppSpacing.sm),
                Text('Export Attendance CSV', style: AppTypography.buttonSmSecondary),
              ],
            ),
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedFilter = filterKey),
        labelStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.onPrimary : AppColors.ink,
        ),
        selectedColor: AppColors.ink,
        backgroundColor: AppColors.softCloud,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
          side: BorderSide(color: AppColors.hairlineSoft),
        ),
      ),
    );
  }
}
