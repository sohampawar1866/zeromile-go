// lib/logic/view_models/domain_context_view_model.dart

import 'package:flutter/foundation.dart';
import '../../models/event_domain.dart';
import '../../models/route_checkpoint.dart';
import '../../data/repositories/domain_repository.dart';
import '../../data/repositories/auth_repository.dart';

enum ActiveRolePerspective { participant, leader, superAdmin, developer }

class DomainContextViewModel extends ChangeNotifier {
  final DomainRepository _domainRepository;
  final AuthRepository _authRepository;

  List<EventDomain> _domains = [];
  EventDomain? _activeDomain;
  List<RouteCheckpoint> _checkpoints = [];
  ActiveRolePerspective _currentRole = ActiveRolePerspective.participant;
  bool _isLoading = false;
  String? _errorMessage;

  DomainContextViewModel({
    DomainRepository? domainRepository,
    AuthRepository? authRepository,
  })  : _domainRepository = domainRepository ?? DomainRepository(),
        _authRepository = authRepository ?? AuthRepository();

  List<EventDomain> get domains => _domains;
  EventDomain? get activeDomain => _activeDomain ?? _domainRepository.activeDomain;
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
      _domains = await _domainRepository.fetchDomains();
      if (_domains.isNotEmpty) {
        _activeDomain = _domains.firstWhere(
          (d) => d.slug == 'cycling-2026',
          orElse: () => _domains.first,
        );
        _domainRepository.setActiveDomain(_activeDomain!);
        await _loadCheckpoints();
      }
      await switchPersonaRole(ActiveRolePerspective.participant);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchDomain(EventDomain domain) async {
    _activeDomain = domain;
    _domainRepository.setActiveDomain(domain);
    await _loadCheckpoints();
    await resolveUserRoleInDomain();
    notifyListeners();
  }

  Future<void> _loadCheckpoints() async {
    if (_activeDomain == null) return;
    try {
      _checkpoints = await _domainRepository.fetchRouteCheckpoints(_activeDomain!.id);
    } catch (_) {
      _checkpoints = [];
    }
  }

  Future<void> switchPersonaRole(ActiveRolePerspective role) async {
    _currentRole = role;
    _isLoading = true;
    notifyListeners();

    String phone = '+91 98240 11111'; // Participant default (Priya Verma)
    if (role == ActiveRolePerspective.leader) phone = '+91 98230 11111'; // Leader (Aniket Deshmukh)
    if (role == ActiveRolePerspective.superAdmin) phone = '+91 98220 11111'; // SuperAdmin (Rajesh Sharma)
    if (role == ActiveRolePerspective.developer) phone = '+91 98000 00000'; // Developer

    try {
      await _authRepository.loginAsDemoPersona(phone);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resolveUserRoleInDomain() async {
    final user = _authRepository.currentUser;
    if (user == null || _activeDomain == null) {
      _currentRole = ActiveRolePerspective.participant;
      return;
    }

    final isSuper = await _authRepository.isSuperAdmin(_activeDomain!.id);
    if (isSuper) {
      _currentRole = ActiveRolePerspective.superAdmin;
      notifyListeners();
      return;
    }

    final isLeader = await _authRepository.isGroupLeader(_activeDomain!.id);
    if (isLeader) {
      _currentRole = ActiveRolePerspective.leader;
      notifyListeners();
      return;
    }

    _currentRole = ActiveRolePerspective.participant;
    notifyListeners();
  }
}
