// lib/data/repositories/auth_repository.dart

import '../../models/user_profile.dart';
import '../../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;
  UserProfile? _cachedUser;

  AuthRepository({AuthService? authService})
      : _authService = authService ?? AuthService();

  UserProfile? get currentUser => _cachedUser ?? _authService.currentUser;

  Future<void> sendOtp(String phoneNumber) async {
    await _authService.sendPhoneOtp(phoneNumber);
  }

  Future<UserProfile> verifyOtpAndLogin({
    required String phoneNumber,
    required String token,
    String? fullName,
    String? emergencyContact,
  }) async {
    final user = await _authService.verifyOtp(
      phoneNumber: phoneNumber,
      token: token,
      fallbackFullName: fullName,
      emergencyContact: emergencyContact,
    );
    _cachedUser = user;
    return user;
  }

  Future<UserProfile> loginAsDemoPersona(String phoneNumber) async {
    final user = await _authService.loginAsDemoPersona(phoneNumber);
    _cachedUser = user;
    return user;
  }

  Future<UserProfile> updateProfile({
    required String fullName,
    String? avatarUrl,
    String? emergencyContact,
  }) async {
    final user = await _authService.updateProfile(
      fullName: fullName,
      avatarUrl: avatarUrl,
      emergencyContact: emergencyContact,
    );
    _cachedUser = user;
    return user;
  }

  Future<bool> isSuperAdmin(String domainId) async {
    return _authService.isSuperAdmin(domainId);
  }

  Future<bool> isGroupLeader(String domainId) async {
    return _authService.isGroupLeader(domainId);
  }

  Future<void> signOut() async {
    _cachedUser = null;
    await _authService.signOut();
  }
}
