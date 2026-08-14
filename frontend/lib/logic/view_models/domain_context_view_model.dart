// lib/logic/view_models/domain_context_view_model.dart

import 'package:flutter/foundation.dart';
import '../../models/event_domain.dart';
import '../../models/route_checkpoint.dart';
import '../../services/domain_service.dart';
import '../../services/auth_service.dart';

enum ActiveRolePerspective { participant, leader, superAdmin, developer }

class DomainContextViewModel extends ChangeNotifier {
  final DomainService _domainService;
  final AuthService _authService;

  List<EventDomain> _domains = [];
  EventDomain? _activeDomain;
  List<RouteCheckpoint> _checkpoints = [];
  ActiveRolePerspective _currentRole = ActiveRolePerspective.participant;
  bool _isLoading = false;
  String? _errorMessage;

  DomainContextViewModel({
    DomainService? domainService,
    AuthService? authService,
  })  : _domainService = domainService ?? DomainService(),
        _authService = authService ?? AuthService();

  List<EventDomain> get domains => _domains;
  EventDomain? get activeDomain => _activeDomain;
  List<RouteCheckpoint> get checkpoints => _checkpoints;
  ActiveRolePerspective get currentRole => _currentRole;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get roleString {
    switch (_currentRole) {
      case ActiveRolePerspective.participant:
        return 'PARTICIPANT';
      case ActiveRolePerspective.leader:
        return 'LEADER';
      case ActiveRolePerspective.superAdmin:
        return 'SUPERADMIN';
      case ActiveRolePerspective.developer:
        return 'DEVELOPER';
    }
  }

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _domains = await _domainService.getDomains();
      if (_domains.isNotEmpty) {
        _activeDomain = _domains.firstWhere(
          (d) => d.slug == 'cycling-2026',
          orElse: () => _domains.first,
        );
        await _loadCheckpoints();
      }
      await switchPersonaRole(ActiveRolePerspective.developer);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchDomain(EventDomain domain) async {
    _activeDomain = domain;
    await _loadCheckpoints();
    await resolveUserRoleInDomain();
    notifyListeners();
  }

  Future<void> _loadCheckpoints() async {
    if (_activeDomain == null) return;
    try {
      _checkpoints = await _domainService.getRouteCheckpoints(_activeDomain!.id);
    } catch (_) {
      _checkpoints = [];
    }
  }

  Future<void> switchPersonaRole(ActiveRolePerspective role) async {
    _currentRole = role;
    _isLoading = true;
    notifyListeners();

    const phone = '+91 8087167841'; // Soham Pawar (Developer Master Console)

    try {
      await _authService.loginAsDemoPersona(phone);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resolveUserRoleInDomain() async {
    final user = _authService.currentUser;
    if (user == null || _activeDomain == null) {
      _currentRole = ActiveRolePerspective.participant;
      return;
    }

    final isSuper = await _authService.isSuperAdmin(_activeDomain!.id);
    if (isSuper) {
      _currentRole = ActiveRolePerspective.superAdmin;
      notifyListeners();
      return;
    }

    final isLeader = await _authService.isGroupLeader(_activeDomain!.id);
    if (isLeader) {
      _currentRole = ActiveRolePerspective.leader;
      notifyListeners();
      return;
    }

    _currentRole = ActiveRolePerspective.participant;
    notifyListeners();
  }
}
