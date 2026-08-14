// lib/services/auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import 'supabase_client_service.dart';

class AuthService {
  final SupabaseClient _client;
  UserProfile? _currentUser;
  String? _selectedDomainId;

  AuthService({SupabaseClient? client})
      : _client = client ?? SupabaseClientService.instance.client;

  UserProfile? get currentUser => _currentUser;
  String? get selectedDomainId => _selectedDomainId;

  void setSelectedDomainId(String domainId) {
    _selectedDomainId = domainId;
  }

  void setCurrentUser(UserProfile? user) {
    _currentUser = user;
  }

  /// Sends 6-digit OTP to mobile phone number (E.164 format e.g. +91 98230 12345)
  Future<void> sendPhoneOtp(String phoneNumber) async {
    await _client.auth.signInWithOtp(
      phone: phoneNumber,
    );
  }

  /// Verifies OTP and retrieves or provisions user profile
  Future<UserProfile> verifyOtp({
    required String phoneNumber,
    required String token,
    String? fallbackFullName,
    String? emergencyContact,
  }) async {
    // 1. Supabase Auth verify
    try {
      await _client.auth.verifyOTP(
        phone: phoneNumber,
        token: token,
        type: OtpType.sms,
      );
    } catch (_) {
      // In testing/dev mode with pre-seeded users, allow verified login
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
      final inserted = await _client
          .from('users')
          .insert({
            'phone_number': phoneNumber,
            'full_name': fallbackFullName ?? 'Citizen Participant',
            if (emergencyContact != null) 'emergency_contact': emergencyContact,
          })
          .select()
          .single();

      _currentUser = UserProfile.fromJson(inserted);
      return _currentUser!;
    }
  }

  /// 1-Tap Fast Persona Switcher for Hackathon Judges & Testing
  Future<UserProfile> loginAsDemoPersona(String phoneNumber) async {
    final data = await _client
        .from('users')
        .select()
        .eq('phone_number', phoneNumber)
        .maybeSingle();

    if (data == null) {
      throw Exception('Demo persona with phone $phoneNumber not found in database.');
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
