// lib/logic/view_models/dev_panel_view_model.dart

import 'package:flutter/foundation.dart';
import '../../models/domain_superadmin.dart';
import '../../services/domain_service.dart';

class DevPanelViewModel extends ChangeNotifier {
  final DomainService _domainService;

  List<DomainSuperAdmin> _provisionedAdmins = [];
  bool _isLoading = false;
  String? _errorMessage;

  DevPanelViewModel({DomainService? domainService})
      : _domainService = domainService ?? DomainService();

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
      _provisionedAdmins = await _domainService.getProvisionedSuperAdmins(domainId);
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
      final newAdmin = await _domainService.provisionSuperAdmin(
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
      await _domainService.createDomain(
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
