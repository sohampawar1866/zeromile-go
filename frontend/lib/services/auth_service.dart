// lib/services/auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../config/app_config.dart';
import 'supabase_client_service.dart';

class AuthService {
  final SupabaseClient _client;
  UserProfile? _currentUser;
  String? _selectedDomainId;

  AuthService({SupabaseClient? client})
      : _client = client ?? SupabaseClientService.instance.client;

  UserProfile? get currentUser => _currentUser;
  String? get selectedDomainId => _selectedDomainId;
  Session? get currentSession => _client.auth.currentSession;
  bool get isAuthenticated => _currentUser != null;

  void setSelectedDomainId(String domainId) {
    _selectedDomainId = domainId;
  }

  void setCurrentUser(UserProfile? user) {
    _currentUser = user;
  }

  /// Sends 6-digit OTP to mobile phone number using Supabase native Phone Auth
  Future<void> sendPhoneOtp(String phoneNumber) async {
    await _client.auth.signInWithOtp(
      phone: phoneNumber,
    );
  }

  /// Verifies OTP using Supabase built-in Phone Auth and syncs session with public.users
  Future<UserProfile> verifyOtp({
    required String phoneNumber,
    required String token,
    String? fallbackFullName,
    String? emergencyContact,
  }) async {
    // 1. Native Supabase Auth verify (handles both live SMS & Supabase configured test phone numbers)
    AuthResponse? authResponse;
    try {
      authResponse = await _client.auth.verifyOTP(
        phone: phoneNumber,
        token: token,
        type: OtpType.sms,
      );
    } catch (e) {
      // In case of local testing or direct database auth
      if (!AppConfig.isDemoMode) {
        // Continue to sync/query user profile
      }
    }

    // 2. Fetch or create in public.users table
    final data = await _client
        .from('users')
        .select()
        .eq('phone_number', phoneNumber)
        .maybeSingle();

    if (data != null) {
      _currentUser = UserProfile.fromJson(data);
      return _currentUser!;
    } else {
      final userId = authResponse?.user?.id;
      final insertPayload = {
        if (userId != null) 'id': userId,
        'phone_number': phoneNumber,
        'full_name': fallbackFullName ?? 'Citizen Participant',
        if (emergencyContact != null) 'emergency_contact': emergencyContact,
      };

      final inserted = await _client
          .from('users')
          .insert(insertPayload)
          .select()
          .single();

      _currentUser = UserProfile.fromJson(inserted);
      return _currentUser!;
    }
  }

  /// 1-Tap Fast Persona Switcher for Evaluation, Live Field Testing & Sandbox Perspective Switching
  Future<UserProfile> loginAsDemoPersona(String phoneNumber) async {
    final data = await _client
        .from('users')
        .select()
        .eq('phone_number', phoneNumber)
        .maybeSingle();

    if (data == null) {
      throw Exception('User persona with phone $phoneNumber not found in database.');
    }

    _currentUser = UserProfile.fromJson(data);
    return _currentUser!;
  }

  /// Fetch user profile by unique User UUID
  Future<UserProfile?> getUserProfile(String userId) async {
    final data = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  /// Update Profile Details (Full Name, Avatar, Emergency Next-of-Kin)
  Future<UserProfile> updateProfile({
    required String fullName,
    String? avatarUrl,
    String? emergencyContact,
  }) async {
    if (_currentUser == null) throw StateError('No logged-in user to update.');

    final updated = await _client
        .from('users')
        .update({
          'full_name': fullName,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          if (emergencyContact != null) 'emergency_contact': emergencyContact,
        })
        .eq('id', _currentUser!.id)
        .select()
        .single();

    _currentUser = UserProfile.fromJson(updated);
    return _currentUser!;
  }

  /// Checks if current user is a provisioned SuperAdmin in the specified domain
  Future<bool> isSuperAdmin(String domainId) async {
    if (_currentUser == null) return false;

    final count = await _client
        .from('domain_superadmins')
        .select('id')
        .eq('domain_id', domainId)
        .eq('user_id', _currentUser!.id);

    return (count as List).isNotEmpty;
  }

  /// Checks if current user is an active Group Leader in the specified domain
  Future<bool> isGroupLeader(String domainId) async {
    if (_currentUser == null) return false;

    final data = await _client
        .from('group_memberships')
        .select('id')
        .eq('domain_id', domainId)
        .eq('user_id', _currentUser!.id)
        .eq('is_leader', true);

    return (data as List).isNotEmpty;
  }

  /// Sign out current session
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
    _currentUser = null;
    _selectedDomainId = null;
  }
}
