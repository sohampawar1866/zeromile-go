// lib/logic/view_models/auth_view_model.dart

import 'package:flutter/foundation.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthViewModel({AuthService? authService})
      : _authService = authService ?? AuthService();

  UserProfile? get currentUser => _currentUser ?? _authService.currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<void> sendOtp(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPhoneOtp(phoneNumber);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp({
    required String phoneNumber,
    required String token,
    String? fullName,
    String? emergencyContact,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.verifyOtp(
        phoneNumber: phoneNumber,
        token: token,
        fallbackFullName: fullName,
        emergencyContact: emergencyContact,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginAsDemoPersona(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.loginAsDemoPersona(phoneNumber);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String fullName,
    String? avatarUrl,
    String? emergencyContact,
  }) async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.updateProfile(
        fullName: fullName,
        avatarUrl: avatarUrl,
        emergencyContact: emergencyContact,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    await _authService.signOut();
    notifyListeners();
  }
}
