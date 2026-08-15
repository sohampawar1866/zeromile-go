// lib/logic/app_state_scope.dart

import 'package:flutter/widgets.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/domain_context_view_model.dart';
import 'view_models/participant_home_view_model.dart';
import 'view_models/groups_view_model.dart';
import 'view_models/leader_hub_view_model.dart';
import 'view_models/superadmin_view_model.dart';
import 'view_models/dev_panel_view_model.dart';

/// Centralized Dependency Injection & State Scope for ZeroMile Go
/// Uses Flutter's native InheritedWidget architecture without external dependencies.
class AppStateScope extends InheritedWidget {
  final AuthViewModel authVm;
  final DomainContextViewModel domainVm;
  final ParticipantHomeViewModel homeVm;
  final GroupsViewModel groupsVm;
  final LeaderHubViewModel leaderVm;
  final SuperAdminViewModel adminVm;
  final DevPanelViewModel devVm;

  const AppStateScope({
    super.key,
    required this.authVm,
    required this.domainVm,
    required this.homeVm,
    required this.groupsVm,
    required this.leaderVm,
    required this.adminVm,
    required this.devVm,
    required super.child,
  });

  static AppStateScope of(BuildContext context) {
    final AppStateScope? result =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(result != null, 'No AppStateScope found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppStateScope oldWidget) {
    return authVm != oldWidget.authVm ||
        domainVm != oldWidget.domainVm ||
        homeVm != oldWidget.homeVm ||
        groupsVm != oldWidget.groupsVm ||
        leaderVm != oldWidget.leaderVm ||
        adminVm != oldWidget.adminVm ||
        devVm != oldWidget.devVm;
  }
}

/// Convenience extensions for accessing ViewModels from BuildContext
extension AppStateScopeExtensions on BuildContext {
  AppStateScope get appState => AppStateScope.of(this);
  AuthViewModel get authVm => AppStateScope.of(this).authVm;
  DomainContextViewModel get domainVm => AppStateScope.of(this).domainVm;
  ParticipantHomeViewModel get homeVm => AppStateScope.of(this).homeVm;
  GroupsViewModel get groupsVm => AppStateScope.of(this).groupsVm;
  LeaderHubViewModel get leaderVm => AppStateScope.of(this).leaderVm;
  SuperAdminViewModel get adminVm => AppStateScope.of(this).adminVm;
  DevPanelViewModel get devVm => AppStateScope.of(this).devVm;
}
