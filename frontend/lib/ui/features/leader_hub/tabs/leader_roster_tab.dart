// lib/ui/features/leader_hub/tabs/leader_roster_tab.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../models/group_membership.dart';
import '../../../../logic/view_models/leader_hub_view_model.dart';
import '../../../../utils/phone_utils.dart';
import '../../../core/dialogs/direct_add_member_modal.dart';
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

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        children: [
          // 1. Attendance Progress Summary Card
          ShadCard(
            title: 'Attendance Roster',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.liveIndicatorBg,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.successBorder),
              ),
              child: Text(
                '$checkedInCount/$totalCount PRESENT',
                style: AppTypography.captionXs.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
                  child: LinearProgressIndicator(
                    value: totalCount > 0 ? (checkedInCount / totalCount) : 0.0,
                    minHeight: 6,
                    backgroundColor: AppColors.hairlineSoft,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Meeting Point: ${widget.viewModel.musterPoint}',
                        style: AppTypography.caption,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${widget.viewModel.checkinPercent.toStringAsFixed(0)}% Ready',
                      style: AppTypography.captionXs.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // 2. Search & Minimal Filter Bar
          TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            decoration: InputDecoration(
              hintText: 'Search members by name or phone...',
              prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.mute),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // 3. Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All (${roster.length})'),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('CHECKED_IN', 'Checked-In ($checkedInCount)'),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('NOT_CHECKED_IN', 'Missing (${roster.where((m) => m.participationStatus == ParticipationStatus.notCheckedIn).length})'),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip('COMPLETED', 'Finished (${widget.viewModel.completedCount})'),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // 4. Roster List Items
          if (filteredRoster.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Column(
                children: [
                  const Icon(Icons.person_search, size: 36, color: AppColors.mute),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _searchQuery.isEmpty ? 'No members found in this filter.' : 'No members matching "$_searchQuery"',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            )
          else
            ...filteredRoster.map((member) => _buildRosterCard(member)),

          const SizedBox(height: 88),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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
                    content: Text('Added $name to team attendance.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          );
        },
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
        ),
        icon: const Icon(Icons.person_add, size: 16),
        label: const Text(
          'ADD MEMBER',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? AppColors.ink : AppColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.captionXs.copyWith(
            color: isSelected ? AppColors.onPrimary : AppColors.charcoal,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRosterCard(GroupMembership member) {
    final status = member.participationStatus;
    final isCheckedIn = status == ParticipationStatus.checkedIn;
    final isCompleted = status == ParticipationStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isCheckedIn
                ? AppColors.successBg
                : isCompleted
                    ? AppColors.infoBg
                    : AppColors.softCloud,
            child: Icon(
              isCheckedIn
                  ? Icons.check
                  : isCompleted
                      ? Icons.flag
                      : Icons.person_outline,
              size: 20,
              color: isCheckedIn
                  ? AppColors.success
                  : isCompleted
                      ? AppColors.info
                      : AppColors.mute,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.userFullName ?? 'Participant',
                        style: AppTypography.bodyStrong,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (member.isLeader)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'LEADER',
                          style: AppTypography.captionXs.copyWith(
                            color: AppColors.onPrimary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  PhoneUtils.formatWithPrefix(
                    PhoneUtils.extract10Digits(member.userPhoneNumber ?? ''),
                    space: true,
                  ),
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ShadButton(
            text: isCheckedIn ? 'Checked-In' : (isCompleted ? 'Finished' : 'Check-In'),
            size: ShadButtonSize.sm,
            variant: isCheckedIn
                ? ShadButtonVariant.success
                : (isCompleted ? ShadButtonVariant.secondary : ShadButtonVariant.outline),
            onPressed: () async {
              final ok = await widget.viewModel.checkInRider(
                domainId: widget.domainId,
                groupId: widget.groupId,
                userId: member.userId,
              );

              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${member.userFullName ?? "Member"} attendance updated.'),
                    backgroundColor: AppColors.ink,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
