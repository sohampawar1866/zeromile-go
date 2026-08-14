// lib/services/domain_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_domain.dart';
import '../models/route_checkpoint.dart';
import '../models/domain_superadmin.dart';
import 'supabase_client_service.dart';

class DomainService {
  final SupabaseClient _client;

  DomainService({SupabaseClient? client})
      : _client = client ?? SupabaseClientService.instance.client;

  /// Fetch all configured Event Domains (Cycling, Marathon, Protest, Walkathon)
  Future<List<EventDomain>> getDomains() async {
    final data = await _client
        .from('event_domains')
        .select()
        .order('created_at', ascending: false);

    return (data as List).map((json) => EventDomain.fromJson(json)).toList();
  }

  /// Get detailed Event Domain by ID
  Future<EventDomain> getDomainById(String domainId) async {
    final data = await _client
        .from('event_domains')
        .select()
        .eq('id', domainId)
        .single();

    return EventDomain.fromJson(data);
  }

  /// Fetch all official checkpoints for the event route
  Future<List<RouteCheckpoint>> getRouteCheckpoints(String domainId) async {
    final data = await _client
        .from('route_checkpoints')
        .select()
        .eq('domain_id', domainId)
        .order('sequence_order', ascending: true);

    return (data as List).map((json) => RouteCheckpoint.fromJson(json)).toList();
  }

  /// Developer Panel: Create a new isolated Event Domain
  Future<EventDomain> createDomain({
    required String name,
    required String slug,
    required String type,
    required DateTime startTime,
    required DateTime endTime,
    Map<String, dynamic>? routeGeojson,
  }) async {
    final inserted = await _client
        .from('event_domains')
        .insert({
          'name': name,
          'slug': slug,
          'type': type,
          'status': 'UPCOMING',
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          if (routeGeojson != null) 'route_geojson': routeGeojson,
        })
        .select()
        .single();

    return EventDomain.fromJson(inserted);
  }

  /// SuperAdmin Console: Update official route geometry & event schedule
  Future<void> updateRouteAndSchedule({
    required String domainId,
    required DateTime startTime,
    required DateTime endTime,
    required String status,
    Map<String, dynamic>? routeGeojson,
  }) async {
    await _client.from('event_domains').update({
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status,
      if (routeGeojson != null) 'route_geojson': routeGeojson,
    }).eq('id', domainId);
  }

  /// Developer Panel: Provision a SuperAdmin for a domain (enforcing 5-6 soft cap)
  Future<DomainSuperAdmin> provisionSuperAdmin({
    required String domainId,
    required String userPhone,
    required String userName,
    String createdByDev = 'developer_panel',
  }) async {
    // 1. Check existing superadmin count
    final existing = await _client
        .from('domain_superadmins')
        .select('id')
        .eq('domain_id', domainId);

    if ((existing as List).length >= 6) {
      throw StateError('Maximum 6 SuperAdmins already provisioned for this domain.');
    }

    // 2. Ensure user exists
    var user = await _client
        .from('users')
        .select('id')
        .eq('phone_number', userPhone)
        .maybeSingle();

    String userId;
    if (user == null) {
      final newUser = await _client
          .from('users')
          .insert({
            'phone_number': userPhone,
            'full_name': userName,
          })
          .select('id')
          .single();
      userId = newUser['id'] as String;
    } else {
      userId = user['id'] as String;
    }

    // 3. Assign role
    final inserted = await _client
        .from('domain_superadmins')
        .insert({
          'domain_id': domainId,
          'user_id': userId,
          'created_by_dev': createdByDev,
        })
        .select('*, users(full_name, phone_number, avatar_url)')
        .single();

    return DomainSuperAdmin.fromJson(inserted);
  }

  /// Developer Panel: List provisioned SuperAdmins for a domain
  Future<List<DomainSuperAdmin>> getProvisionedSuperAdmins(String domainId) async {
    final data = await _client
        .from('domain_superadmins')
        .select('*, users(full_name, phone_number, avatar_url)')
        .eq('domain_id', domainId)
        .order('assigned_at', ascending: true);

    return (data as List).map((json) => DomainSuperAdmin.fromJson(json)).toList();
  }
}
