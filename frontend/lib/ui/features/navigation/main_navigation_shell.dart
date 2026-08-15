// lib/ui/features/navigation/main_navigation_shell.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../logic/view_models/domain_context_view_model.dart';
import '../../../logic/view_models/auth_view_model.dart';
import '../../../logic/view_models/participant_home_view_model.dart';
import '../../../logic/view_models/groups_view_model.dart';
import '../../../logic/view_models/leader_hub_view_model.dart';
import '../../../logic/view_models/superadmin_view_model.dart';
import '../../../logic/view_models/dev_panel_view_model.dart';
import '../home/participant_home_screen.dart';
import '../home/participant_live_map_screen.dart';
import '../groups/my_groups_screen.dart';
import '../leader_hub/leader_hub_screen.dart';
import '../admin_console/superadmin_console_screen.dart';
import '../dev_panel/dev_panel_screen.dart';
import '../profile/profile_screen.dart';
import 'app_drawer.dart';

class MainNavigationShell extends StatefulWidget {
  final DomainContextViewModel domainContextVm;
  final AuthViewModel authVm;
  final ParticipantHomeViewModel participantHomeVm;
  final GroupsViewModel groupsVm;
  final LeaderHubViewModel leaderHubVm;
  final SuperAdminViewModel superAdminVm;
  final DevPanelViewModel devPanelVm;

  const MainNavigationShell({
    super.key,
    required this.domainContextVm,
    required this.authVm,
    required this.participantHomeVm,
    required this.groupsVm,
    required this.leaderHubVm,
    required this.superAdminVm,
    required this.devPanelVm,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _bottomNavIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final role = widget.domainContextVm.currentRole;
    final domain = widget.domainContextVm.activeDomain;
    final user = widget.authVm.currentUser;
    final domainId = domain?.id ?? '00000000-0000-0000-0000-000000000001';
    final userId = user?.id ?? '00000000-0000-0000-0000-000000000001';
    final isMapTab = role == ActiveRolePerspective.participant && _bottomNavIndex == 1;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.canvas,
      appBar: isMapTab
          ? null
          : AppBar(
        titleSpacing: 0,
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm),
          child: GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Center(
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight.withOpacity(0.15),
                child: const Icon(Icons.person, color: AppColors.primary, size: 20),
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: AppColors.primary, size: 18),
            const SizedBox(width: 4),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Location',
                    style: AppTypography.captionXs.copyWith(color: AppColors.mute, fontSize: 9),
                  ),
                  Text(
                    'Nagpur, MH',
                    style: AppTypography.bodySm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Role Perspective Chip
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: role == ActiveRolePerspective.superAdmin
                    ? AppColors.sale
                    : role == ActiveRolePerspective.leader
                        ? AppColors.ink
                        : AppColors.softCloud,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Center(
                child: Text(
                  widget.domainContextVm.roleString.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: (role == ActiveRolePerspective.superAdmin || role == ActiveRolePerspective.leader)
                        ? AppColors.onPrimary
                        : AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Notification Bell
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, color: AppColors.ink, size: 22),
                if (widget.participantHomeVm.broadcasts.isNotEmpty)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.sale,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    widget.participantHomeVm.broadcasts.isNotEmpty
                        ? 'Latest: ${widget.participantHomeVm.broadcasts.first.messageText}'
                        : 'No new notifications.',
                  ),
                  backgroundColor: AppColors.ink,
                ),
              );
            },
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      drawer: AppDrawer(
        currentUser: user,
        activeDomain: domain,
        allDomains: widget.domainContextVm.domains,
        currentRole: role,
        roleString: widget.domainContextVm.roleString,
        selectedNavIndex: _bottomNavIndex,
        onSelectNavIndex: (idx) => setState(() => _bottomNavIndex = idx),
        onSelectRole: (newRole) async {
          setState(() => _bottomNavIndex = 0);
          await widget.domainContextVm.switchPersonaRole(newRole);
          final activeDomId = widget.domainContextVm.activeDomain?.id ?? domainId;
          final activeUsrId = widget.authVm.currentUser?.id ?? userId;

          if (newRole == ActiveRolePerspective.participant) {
            await widget.participantHomeVm.loadParticipantContext(domainId: activeDomId, userId: activeUsrId);
            await widget.groupsVm.loadGroups(domainId: activeDomId, userId: activeUsrId);
          } else if (newRole == ActiveRolePerspective.leader) {
            await widget.groupsVm.loadGroups(domainId: activeDomId, userId: activeUsrId);
            final ledGroup = widget.groupsVm.userMemberships.where((m) => m.isLeader).firstOrNull ??
                widget.groupsVm.userMemberships.where((m) => m.isActive).firstOrNull ??
                widget.groupsVm.userMemberships.firstOrNull;
            final targetGroupId = ledGroup?.groupId ?? 'd755b533-e975-41c0-8a88-ed0b30e60a7c';
            await widget.leaderHubVm.loadLeaderContext(domainId: activeDomId, groupId: targetGroupId);
          } else if (newRole == ActiveRolePerspective.superAdmin) {
            await widget.superAdminVm.loadAdminContext(activeDomId);
          } else if (newRole == ActiveRolePerspective.developer) {
            await widget.devPanelVm.loadProvisionedAdmins(activeDomId);
            await widget.devPanelVm.loadGlobalMetrics();
          }
        },
        onSwitchDomain: (newDom) async {
          await widget.domainContextVm.switchDomain(newDom);
          await widget.participantHomeVm.loadParticipantContext(domainId: newDom.id, userId: userId);
        },
      ),
      body: _buildActiveRoleBody(role, domainId, userId),
      bottomNavigationBar: _buildBottomNavigationBar(role),
    );
  }

  Widget? _buildBottomNavigationBar(ActiveRolePerspective role) {
    if (role == ActiveRolePerspective.participant) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.hairline, width: 1.0)),
        ),
        child: BottomNavigationBar(
          currentIndex: _bottomNavIndex.clamp(0, 3),
          onTap: (idx) => setState(() => _bottomNavIndex = idx),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.mute,
          selectedLabelStyle: AppTypography.captionXs.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: AppTypography.captionXs,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.near_me_outlined),
              activeIcon: Icon(Icons.near_me),
              label: 'Ongoing',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups),
              label: 'Groups',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      );
    }

    if (role == ActiveRolePerspective.leader) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.hairline, width: 1.0)),
        ),
        child: BottomNavigationBar(
          currentIndex: _bottomNavIndex.clamp(0, 2),
          onTap: (idx) => setState(() => _bottomNavIndex = idx),
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.mute,
          selectedLabelStyle: AppTypography.captionXs.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: AppTypography.captionXs,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined),
              activeIcon: Icon(Icons.shield),
              label: 'Leader Hub',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups),
              label: 'All Groups',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      );
    }

    return null;
  }

  Widget _buildActiveRoleBody(ActiveRolePerspective role, String domainId, String userId) {
    final user = widget.authVm.currentUser;

    switch (role) {
      case ActiveRolePerspective.leader:
        if (_bottomNavIndex == 1) {
          return MyGroupsScreen(
            viewModel: widget.groupsVm,
            domainId: domainId,
            userId: userId,
          );
        }
        if (_bottomNavIndex == 2) {
          return ProfileScreen(
            currentUser: user,
            activeDomain: widget.domainContextVm.activeDomain,
            activeMembership: widget.participantHomeVm.activeMembership,
            authVm: widget.authVm,
            groupsVm: widget.groupsVm,
            onManageGroups: () => setState(() => _bottomNavIndex = 1),
          );
        }
        final ledGroup = widget.groupsVm.userMemberships.where((m) => m.isLeader).firstOrNull ??
            widget.groupsVm.userMemberships.firstOrNull;
        final targetGroupId = ledGroup?.groupId ?? 'd755b533-e975-41c0-8a88-ed0b30e60a7c';
        return LeaderHubScreen(
          activeDomain: widget.domainContextVm.activeDomain,
          viewModel: widget.leaderHubVm,
          leaderUserId: userId,
          groupId: targetGroupId,
        );

      case ActiveRolePerspective.superAdmin:
        return SuperAdminConsoleScreen(
          activeDomain: widget.domainContextVm.activeDomain,
          viewModel: widget.superAdminVm,
          adminUserId: userId,
        );

      case ActiveRolePerspective.developer:
        return DevPanelScreen(
          activeDomain: widget.domainContextVm.activeDomain,
          viewModel: widget.devPanelVm,
        );

      case ActiveRolePerspective.participant:
        if (_bottomNavIndex == 1) {
          return ParticipantLiveMapScreen(
            activeDomain: widget.domainContextVm.activeDomain,
            checkpoints: widget.domainContextVm.checkpoints,
            viewModel: widget.participantHomeVm,
            currentUserId: userId,
          );
        }
        if (_bottomNavIndex == 2) {
          return MyGroupsScreen(
            viewModel: widget.groupsVm,
            domainId: domainId,
            userId: userId,
          );
        }
        if (_bottomNavIndex == 3) {
          return ProfileScreen(
            currentUser: user,
            activeDomain: widget.domainContextVm.activeDomain,
            activeMembership: widget.participantHomeVm.activeMembership,
            authVm: widget.authVm,
            groupsVm: widget.groupsVm,
            domainContextVm: widget.domainContextVm,
            onManageGroups: () => setState(() => _bottomNavIndex = 2),
          );
        }
        return ParticipantHomeScreen(
          activeDomain: widget.domainContextVm.activeDomain,
          checkpoints: widget.domainContextVm.checkpoints,
          viewModel: widget.participantHomeVm,
          currentUserId: userId,
          onNavigateToGroups: () => setState(() => _bottomNavIndex = 2),
          onNavigateToMap: () => setState(() => _bottomNavIndex = 1),
        );
    }
  }
}
