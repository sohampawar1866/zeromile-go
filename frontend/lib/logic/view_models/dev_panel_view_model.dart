// lib/logic/view_models/dev_panel_view_model.dart

import 'package:flutter/foundation.dart';
import '../../data/models/domain_superadmin.dart';
import '../../data/repositories/domain_repository.dart';

class DevPanelViewModel extends ChangeNotifier {
  final DomainRepository _domainRepository;

  List<DomainSuperAdmin> _provisionedAdmins = [];
  bool _isLoading = false;
  String? _errorMessage;

  DevPanelViewModel({DomainRepository? domainRepository})
      : _domainRepository = domainRepository ?? DomainRepository();

  List<DomainSuperAdmin> get provisionedAdmins => _provisionedAdmins;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get adminSeatCount => _provisionedAdmins.length;
  bool get isSeatCapReached => _provisionedAdmins.length >= 6;

  Future<void> loadProvisionedAdmins(String domainId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _provisionedAdmins = await _domainRepository.fetchProvisionedSuperAdmins(domainId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> provisionNewAdmin({
    required String domainId,
    required String userPhone,
    required String userName,
  }) async {
    if (isSeatCapReached) {
      _errorMessage = 'Maximum 6 SuperAdmin seats already provisioned for this domain.';
      notifyListeners();
      return false;
    }

    try {
      final newAdmin = await _domainRepository.provisionSuperAdmin(
        domainId: domainId,
        userPhone: userPhone,
        userName: userName,
      );
      _provisionedAdmins.add(newAdmin);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> createNewDomain({
    required String name,
    required String slug,
    required String type,
    required DateTime startTime,
    required DateTime endTime,
    Map<String, dynamic>? routeGeojson,
  }) async {
    try {
      await _domainRepository.createDomain(
        name: name,
        slug: slug,
        type: type,
        startTime: startTime,
        endTime: endTime,
        routeGeojson: routeGeojson,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }
}
