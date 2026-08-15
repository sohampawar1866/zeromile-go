// lib/ui/features/groups/my_groups_screen.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../logic/view_models/groups_view_model.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/components/shad_button.dart';
import '../../core/components/shad_card.dart';

class MyGroupsScreen extends StatefulWidget {
  final GroupsViewModel viewModel;
  final String domainId;
  final String userId;

  const MyGroupsScreen({
    super.key,
    required this.viewModel,
    required this.domainId,
    required this.userId,
  });

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadGroups(
      domainId: widget.domainId,
      userId: widget.userId,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final memberships = widget.viewModel.userMemberships;
        final joinedGroupIds = memberships.map((m) => m.groupId).toSet();
        final joinedCount = memberships.length;
        final isMaxReached = joinedCount >= 3;

        // Filter available domain clubs/sub-groups by search query
        final availableGroups = widget.viewModel.domainGroups.where((g) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          final matchesName = g.name.toLowerCase().contains(q);
          final matchesType = g.orgType.toLowerCase().contains(q);
          final matchesMuster = (g.musterPoint ?? '').toLowerCase().contains(q);
          return matchesName || matchesType || matchesMuster;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: RefreshIndicator(
            color: AppColors.ink,
            backgroundColor: AppColors.surface,
            onRefresh: () => widget.viewModel.loadGroups(
              domainId: widget.domainId,
              userId: widget.userId,
            ),
            child: ListView(
              padding: AppSpacing.edgeInsetsScreen,
              children: [
                // Quota & Rules Card
                ShadCard(
                  title: 'Contingent Quota',
                  trailing: StatusBadge(
                    label: '$joinedCount/3 Joined',
                    type: isMaxReached ? StatusBadgeType.warning : StatusBadgeType.success,
                  ),
                  child: const Text(
                    'You may join up to 3 sub-groups per event, but you can only designate ONE active contingent for live telemetry and SOS triage routing.',
                    style: AppTypography.bodySm,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Enrolled Groups List
                ShadCard(
                  title: 'Enrolled Sub-Groups',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (memberships.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Center(
                            child: Text(
                              'You have not joined any sub-groups yet.\nBrowse available clubs below to join.',
                              textAlign: TextAlign.center,
                              style: AppTypography.caption,
                            ),
                          ),
                        )
                      else
                        ...memberships.map((m) {
                          final isActive = m.isActive;

                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.liveIndicatorBg : AppColors.softCloud,
                              borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                              border: Border.all(
                                color: isActive ? AppColors.successBorder : AppColors.hairline,
                                width: isActive ? 1.5 : 1.0,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                                onTap: () async {
                                  final ok = await widget.viewModel.switchActiveGroup(
                                    domainId: widget.domainId,
                                    groupId: m.groupId,
                                    userId: widget.userId,
                                  );
                                  if (context.mounted && ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Active contingent updated.'),
                                        backgroundColor: AppColors.ink,
                                      ),
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: AppSpacing.edgeInsetsCard,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        margin: const EdgeInsets.only(right: AppSpacing.sm),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isActive ? AppColors.success : Colors.transparent,
                                          border: Border.all(
                                            color: isActive ? AppColors.success : AppColors.hairlineLight,
                                            width: 2,
                                          ),
                                        ),
                                        child: isActive
                                            ? const Icon(Icons.check, size: 14, color: AppColors.onPrimary)
                                            : null,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              m.groupName ?? 'Contingent Group',
                                              style: AppTypography.bodyStrong,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Status: ${m.participationStatus.name.toUpperCase()}',
                                              style: AppTypography.caption,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (m.isLeader)
                                        const Padding(
                                          padding: EdgeInsets.only(left: AppSpacing.xs),
                                          child: StatusBadge(label: 'Leader', type: StatusBadgeType.warning),
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
                const SizedBox(height: AppSpacing.md),

                // Discover & Join Clubs Section
                ShadCard(
                  title: 'Discover & Join Clubs',
                  description: 'Search official clubs and contingents participating in this event domain.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search club or contingent by name...',
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.mute),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18, color: AppColors.mute),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Club Cards List
                      if (availableGroups.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          child: Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'No clubs available in this domain yet.'
                                  : 'No clubs match "$_searchQuery".',
                              style: AppTypography.caption,
                            ),
                          ),
                        )
                      else
                        ...availableGroups.map((group) {
                          final isAlreadyJoined = joinedGroupIds.contains(group.id);

                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            padding: AppSpacing.edgeInsetsCard,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                              border: Border.all(color: AppColors.hairline),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: AppColors.softCloud,
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                        border: Border.all(color: AppColors.hairline),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        _getOrgTypeIcon(group.orgType),
                                        color: AppColors.ink,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            group.name,
                                            style: AppTypography.bodyStrong,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatOrgType(group.orgType),
                                            style: AppTypography.captionXs.copyWith(color: AppColors.mute),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isAlreadyJoined)
                                      const StatusBadge(label: 'Enrolled', type: StatusBadgeType.success)
                                    else if (isMaxReached)
                                      const StatusBadge(label: 'Quota Full', type: StatusBadgeType.muted)
                                    else
                                      ShadButton(
                                        text: 'Join',
                                        icon: Icons.add,
                                        size: ShadButtonSize.sm,
                                        variant: ShadButtonVariant.primary,
                                        onPressed: () async {
                                          final ok = await widget.viewModel.joinGroup(
                                            domainId: widget.domainId,
                                            groupId: group.id,
                                            userId: widget.userId,
                                            setActive: joinedCount == 0,
                                          );
                                          if (context.mounted && ok) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Joined ${group.name}!'),
                                                backgroundColor: AppColors.success,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                  ],
                                ),
                                if (group.musterPoint != null && group.musterPoint!.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.mute),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Muster: ${group.musterPoint}',
                                          style: AppTypography.captionXs,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getOrgTypeIcon(String orgType) {
    switch (orgType.toUpperCase()) {
      case 'CYCLING_CLUB':
      case 'CYCLING':
        return Icons.directions_bike;
      case 'CORPORATE':
        return Icons.business_outlined;
      case 'COLLEGE':
      case 'UNIVERSITY':
        return Icons.school_outlined;
      case 'COMMUNITY':
        return Icons.people_outline;
      default:
        return Icons.groups_outlined;
    }
  }

  String _formatOrgType(String orgType) {
    return orgType.replaceAll('_', ' ').toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
