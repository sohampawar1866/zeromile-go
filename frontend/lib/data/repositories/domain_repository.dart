// lib/data/repositories/domain_repository.dart

import '../../models/event_domain.dart';
import '../../models/route_checkpoint.dart';
import '../../models/domain_superadmin.dart';
import '../../services/domain_service.dart';

class DomainRepository {
  final DomainService _domainService;
  List<EventDomain> _cachedDomains = [];
  EventDomain? _activeDomain;

  DomainRepository({DomainService? domainService})
      : _domainService = domainService ?? DomainService();

  List<EventDomain> get domains => _cachedDomains;
  EventDomain? get activeDomain => _activeDomain;

  void setActiveDomain(EventDomain domain) {
    _activeDomain = domain;
  }

  Future<List<EventDomain>> fetchDomains({bool forceRefresh = false}) async {
    if (_cachedDomains.isNotEmpty && !forceRefresh) return _cachedDomains;
    _cachedDomains = await _domainService.getDomains();
    if (_activeDomain == null && _cachedDomains.isNotEmpty) {
      _activeDomain = _cachedDomains.firstWhere(
        (d) => d.slug == 'cycling-2026',
        orElse: () => _cachedDomains.first,
      );
    }
    return _cachedDomains;
  }

  Future<List<RouteCheckpoint>> fetchRouteCheckpoints(String domainId) async {
    return _domainService.getRouteCheckpoints(domainId);
  }

  Future<EventDomain> createDomain({
    required String name,
    required String slug,
    required String type,
    required DateTime startTime,
    required DateTime endTime,
    Map<String, dynamic>? routeGeojson,
  }) async {
    final domain = await _domainService.createDomain(
      name: name,
      slug: slug,
      type: type,
      startTime: startTime,
      endTime: endTime,
      routeGeojson: routeGeojson,
    );
    _cachedDomains.insert(0, domain);
    return domain;
  }

  Future<void> updateRouteAndSchedule({
    required String domainId,
    required DateTime startTime,
    required DateTime endTime,
    required String status,
    Map<String, dynamic>? routeGeojson,
  }) async {
    await _domainService.updateRouteAndSchedule(
      domainId: domainId,
      startTime: startTime,
      endTime: endTime,
      status: status,
      routeGeojson: routeGeojson,
    );
    await fetchDomains(forceRefresh: true);
  }

  Future<DomainSuperAdmin> provisionSuperAdmin({
    required String domainId,
    required String userPhone,
    required String userName,
  }) async {
    return _domainService.provisionSuperAdmin(
      domainId: domainId,
      userPhone: userPhone,
      userName: userName,
    );
  }

  Future<List<DomainSuperAdmin>> fetchProvisionedSuperAdmins(String domainId) async {
    return _domainService.getProvisionedSuperAdmins(domainId);
  }
}
