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
import '../groups/my_groups_screen.dart';
import '../leader_hub/leader_hub_screen.dart';
import '../admin_console/superadmin_console_screen.dart';
import '../dev_panel/dev_panel_screen.dart';
import 'app_drawer.dart';
import '../../core/dialogs/group_creation_modal.dart';

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

class _MainNavigationShellState extends State<MainNavigationShell> with SingleTickerProviderStateMixin {
  int _bottomNavIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.90, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.domainContextVm.currentRole;
    final domain = widget.domainContextVm.activeDomain;
    final user = widget.authVm.currentUser;
    final domainId = domain?.id ?? 'cycling-domain';
    final userId = user?.id ?? 'u0000000-0000-0000-0000-000000000008';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_bike, color: AppColors.ink, size: 20),
            const SizedBox(width: AppSpacing.xs + 2),
            Flexible(
              child: Text(
                domain?.name ?? 'ZeroMile Go',
                style: AppTypography.headingMd,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.liveIndicatorBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'LIVE',
                  style: AppTypography.captionXs.copyWith(
                    color: AppColors.liveIndicatorText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Persona Switcher Dropdown (Compact Nike pill)
          PopupMenuButton<ActiveRolePerspective>(
            tooltip: 'Switch Role Persona',
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.md),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.domainContextVm.roleString,
                    style: AppTypography.captionXs.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down, size: 14, color: AppColors.onPrimary),
                ],
              ),
            ),
            onSelected: (newRole) async {
              await widget.domainContextVm.switchPersonaRole(newRole);
              if (newRole == ActiveRolePerspective.participant) {
                await widget.participantHomeVm.loadParticipantContext(domainId: domainId, userId: userId);
              } else if (newRole == ActiveRolePerspective.leader) {
                await widget.leaderHubVm.loadLeaderContext(domainId: domainId, groupId: 'g0000000-0000-0000-0000-000000000002');
              } else if (newRole == ActiveRolePerspective.superAdmin) {
                await widget.superAdminVm.loadAdminContext(domainId);
              } else if (newRole == ActiveRolePerspective.developer) {
                await widget.devPanelVm.loadProvisionedAdmins(domainId);
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: ActiveRolePerspective.participant,
                child: Text('Participant: Priya Verma (+91 98240 11111)'),
              ),
              PopupMenuItem(
                value: ActiveRolePerspective.leader,
                child: Text('Group Leader: Aniket Deshmukh (+91 98230 11111)'),
              ),
              PopupMenuItem(
                value: ActiveRolePerspective.superAdmin,
                child: Text('SuperAdmin: Rajesh Sharma (+91 98220 11111)'),
              ),
              PopupMenuItem(
                value: ActiveRolePerspective.developer,
                child: Text('Developer Master Console (+91 98000 00000)'),
              ),
            ],
          ),
        ],
      ),
      drawer: AppDrawer(
        currentUser: user,
        activeDomain: domain,
        allDomains: widget.domainContextVm.domains,
        selectedNavIndex: _bottomNavIndex,
        onSelectNavIndex: (idx) => setState(() => _bottomNavIndex = idx),
        onSwitchDomain: (newDom) async {
          await widget.domainContextVm.switchDomain(newDom);
          await widget.participantHomeVm.loadParticipantContext(domainId: newDom.id, userId: userId);
        },
        onGroupProposal: ({
          required orgName,
          required orgType,
          required expectedCount,
          required musterPoint,
          leaderNotes,
        }) async {
          final ok = await widget.groupsVm.submitGroupProposal(
            domainId: domainId,
            applicantUserId: userId,
            orgName: orgName,
            orgType: orgType,
            expectedCount: expectedCount,
            musterPoint: musterPoint,
            leaderNotes: leaderNotes,
          );
          if (context.mounted && ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contingent proposal submitted to SuperAdmins.'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      ),
      body: _buildActiveRoleBody(role, domainId, userId),
      bottomNavigationBar: role == ActiveRolePerspective.participant
          ? Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.hairlineSoft, width: 1.0)),
              ),
              child: BottomNavigationBar(
                currentIndex: _bottomNavIndex,
                onTap: (idx) => setState(() => _bottomNavIndex = idx),
                backgroundColor: AppColors.canvas,
                selectedItemColor: AppColors.ink,
                unselectedItemColor: AppColors.mute,
                selectedLabelStyle: AppTypography.captionXs.copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle: AppTypography.captionXs,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.groups_outlined),
                    activeIcon: Icon(Icons.groups),
                    label: 'My Groups',
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildActiveRoleBody(ActiveRolePerspective role, String domainId, String userId) {
    switch (role) {
      case ActiveRolePerspective.leader:
        return LeaderHubScreen(
          activeDomain: widget.domainContextVm.activeDomain,
          viewModel: widget.leaderHubVm,
          leaderUserId: userId,
          groupId: 'g0000000-0000-0000-0000-000000000002',
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
          return MyGroupsScreen(
            viewModel: widget.groupsVm,
            domainId: domainId,
            userId: userId,
          );
        }
        return ParticipantHomeScreen(
          activeDomain: widget.domainContextVm.activeDomain,
          checkpoints: widget.domainContextVm.checkpoints,
          viewModel: widget.participantHomeVm,
          currentUserId: userId,
          onNavigateToGroups: () => setState(() => _bottomNavIndex = 1),
          onOpenProposeModal: () {
            GroupCreationModal.show(
              context,
              onSubmit: ({
                required orgName,
                required orgType,
                required expectedCount,
                required musterPoint,
                leaderNotes,
              }) async {
                await widget.groupsVm.submitGroupProposal(
                  domainId: domainId,
                  applicantUserId: userId,
                  orgName: orgName,
                  orgType: orgType,
                  expectedCount: expectedCount,
                  musterPoint: musterPoint,
                  leaderNotes: leaderNotes,
                );
              },
            );
          },
        );
    }
  }
}
