// lib/ui/features/navigation/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../models/event_domain.dart';
import '../../../models/user_profile.dart';
import '../../../logic/view_models/domain_context_view_model.dart';
import '../../../logic/view_models/map_test_mode_notifier.dart';
import '../../core/dialogs/switch_domain_modal.dart';
import '../../core/widgets/fluid_tap_scale.dart';
import '../../../utils/phone_utils.dart';

class AppDrawer extends StatelessWidget {
  final UserProfile? currentUser;
  final EventDomain? activeDomain;
  final List<EventDomain> allDomains;
  final ActiveRolePerspective currentRole;
  final String roleString;
  final int selectedNavIndex;
  final ValueChanged<int> onSelectNavIndex;
  final ValueChanged<EventDomain> onSwitchDomain;
  final ValueChanged<ActiveRolePerspective> onSelectRole;

  const AppDrawer({
    super.key,
    required this.currentUser,
    required this.activeDomain,
    required this.allDomains,
    required this.currentRole,
    required this.roleString,
    required this.selectedNavIndex,
    required this.onSelectNavIndex,
    required this.onSwitchDomain,
    required this.onSelectRole,
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
                    PhoneUtils.formatDisplay(currentUser?.phoneNumber ?? '8087167841'),
                    style: AppTypography.caption,
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
                    icon: Icons.map_outlined,
                    label: 'Live Route Map',
                    isSelected: selectedNavIndex == 1,
                    onTap: () {
                      onSelectNavIndex(1);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.groups_outlined,
                    label: 'My Groups & Clubs',
                    isSelected: selectedNavIndex == 2,
                    onTap: () {
                      onSelectNavIndex(2);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person_outline,
                    label: 'My Profile & Pass',
                    isSelected: selectedNavIndex == 3,
                    onTap: () {
                      onSelectNavIndex(3);
                      Navigator.pop(context);
                    },
                  ),

                  // ── Test Mode Toggle ──────────────────────────────────
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(color: AppColors.hairlineSoft, height: 1),
                  const SizedBox(height: AppSpacing.sm),
                  Consumer<MapTestModeNotifier?>(
                    builder: (ctx, notifier, _) {
                      final isActive = notifier?.isTestMode ?? false;
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.warningBg
                              : AppColors.softCloud,
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isActive
                                ? AppColors.warning
                                : AppColors.hairline,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.science_outlined,
                              size: 18,
                              color: isActive
                                  ? AppColors.warningAccent
                                  : AppColors.mute,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Test Mode',
                                        style: AppTypography.bodyStrong
                                            .copyWith(
                                          color: isActive
                                              ? AppColors.warningAccent
                                              : AppColors.charcoal,
                                        ),
                                      ),
                                      if (isActive) ...
                                      [
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppColors.warning,
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.pill),
                                          ),
                                          child: const Text(
                                            'ACTIVE',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    isActive
                                        ? 'Simulated riders visible on map'
                                        : 'Simulated riders inactive',
                                    style: AppTypography.captionXs
                                        .copyWith(color: AppColors.mute),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isActive,
                              activeColor: AppColors.warningAccent,
                              onChanged: (val) {
                                ctx
                                    .read<MapTestModeNotifier?>()
                                    ?.setValue(val);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),

            // Bottom Fixed Section: Role Switcher + Switch Event Button
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.hairlineSoft, width: 1.0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Role Switcher
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: PopupMenuButton<ActiveRolePerspective>(
                      tooltip: 'Switch Role',
                      onSelected: (role) {
                        Navigator.pop(context);
                        onSelectRole(role);
                      },
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(
                          value: ActiveRolePerspective.participant,
                          child: Text('Participant (Rider)'),
                        ),
                        PopupMenuItem(
                          value: ActiveRolePerspective.leader,
                          child: Text('Group Leader'),
                        ),
                        PopupMenuItem(
                          value: ActiveRolePerspective.superAdmin,
                          child: Text('SuperAdmin (Organizer)'),
                        ),
                        PopupMenuItem(
                          value: ActiveRolePerspective.developer,
                          child: Text('Developer (Debug)'),
                        ),
                      ],
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.admin_panel_settings_outlined,
                              color: AppColors.onPrimary,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'ACTIVE ROLE',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      color: AppColors.stone,
                                    ),
                                  ),
                                  Text(
                                    roleString.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.onPrimary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),


                  // Fixed Bottom Action: Distinct "Switch Event Domain" Button
                  FluidTapScale(
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
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm + 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softCloud,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.ink, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xs + 1),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Icon(
                              Icons.swap_horiz_rounded,
                              color: AppColors.onPrimary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'SWITCH EVENT DOMAIN',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  activeDomain?.name ?? 'Select Domain',
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.mute,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.ink,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
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
