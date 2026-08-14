// lib/ui/features/navigation/app_drawer.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../models/event_domain.dart';
import '../../../models/user_profile.dart';
import '../../core/dialogs/switch_domain_modal.dart';
import '../../core/dialogs/group_creation_modal.dart';

class AppDrawer extends StatelessWidget {
  final UserProfile? currentUser;
  final EventDomain? activeDomain;
  final List<EventDomain> allDomains;
  final int selectedNavIndex;
  final ValueChanged<int> onSelectNavIndex;
  final ValueChanged<EventDomain> onSwitchDomain;
  final Function({
    required String orgName,
    required String orgType,
    required int expectedCount,
    required String musterPoint,
    String? leaderNotes,
  }) onGroupProposal;

  const AppDrawer({
    super.key,
    required this.currentUser,
    required this.activeDomain,
    required this.allDomains,
    required this.selectedNavIndex,
    required this.onSelectNavIndex,
    required this.onSwitchDomain,
    required this.onGroupProposal,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.canvas,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.hairlineSoft, width: 1.0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: const BoxDecoration(
                          color: AppColors.ink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.directions_bike, color: AppColors.onPrimary, size: 22),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs + 1),
                        decoration: BoxDecoration(
                          color: AppColors.liveIndicatorBg,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'LIVE ONLINE',
                          style: AppTypography.captionXs.copyWith(
                            color: AppColors.liveIndicatorText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    currentUser?.fullName ?? 'Soham Pawar',
                    style: AppTypography.headingMd,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currentUser?.phoneNumber ?? '+91 8087167841',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Domain Switcher Bar
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      SwitchDomainModal.show(
                        context,
                        currentDomain: activeDomain,
                        domains: allDomains,
                        onSelectDomain: onSwitchDomain,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.softCloud,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.hairlineSoft),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tune, size: 14, color: AppColors.ink),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ACTIVE RALLY DOMAIN', style: AppTypography.captionXs),
                                Text(
                                  activeDomain?.name ?? 'Cycling Rally 2026',
                                  style: AppTypography.bodyStrong,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_right, size: 16, color: AppColors.ink),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Navigation List Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.home_outlined,
                    label: 'Live Rally Dashboard',
                    isSelected: selectedNavIndex == 0,
                    onTap: () {
                      onSelectNavIndex(0);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.groups_outlined,
                    label: 'My Sub-Groups (Contingent)',
                    isSelected: selectedNavIndex == 1,
                    onTap: () {
                      onSelectNavIndex(1);
                      Navigator.pop(context);
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    child: Divider(),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.add_business_outlined,
                    label: 'Propose New Sub-Group',
                    onTap: () {
                      Navigator.pop(context);
                      GroupCreationModal.show(
                        context,
                        onSubmit: onGroupProposal,
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.alt_route,
                    label: 'Switch Event Domain',
                    onTap: () {
                      Navigator.pop(context);
                      SwitchDomainModal.show(
                        context,
                        currentDomain: activeDomain,
                        domains: allDomains,
                        onSelectDomain: onSwitchDomain,
                      );
                    },
                  ),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  const Text(
                    'ZeroMile Go • Nagpur Municipal Corp',
                    style: AppTypography.captionXs,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Build v2.4.0 • ZeroMile Architecture',
                    style: AppTypography.captionXs.copyWith(color: AppColors.stone),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.softCloud : AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.ink : AppColors.mute,
          size: 20,
        ),
        title: Text(
          label,
          style: AppTypography.bodyStrong.copyWith(
            color: isSelected ? AppColors.ink : AppColors.charcoal,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap,
        dense: true,
      ),
    );
  }
}
