// test/models/dto_serialization_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_core/flutter_core.dart';

void main() {
  group('DTO Models Serialization & Deserialization Tests', () {
    test('EventDomain parses from JSON and serializes back', () {
      final json = {
        'id': 'd0000000-0000-0000-0000-000000000001',
        'name': 'Cycling Rally 2026',
        'slug': 'cycling-2026',
        'type': 'CYCLING',
        'status': 'LIVE_ACTIVE',
        'start_time': '2026-08-14T06:00:00.000Z',
        'end_time': '2026-08-14T11:30:00.000Z',
        'route_geojson': {'type': 'FeatureCollection', 'features': []},
        'created_at': '2026-08-14T00:00:00.000Z',
      };

      final domain = EventDomain.fromJson(json);
      expect(domain.name, equals('Cycling Rally 2026'));
      expect(domain.type, equals(EventDomainType.cycling));
      expect(domain.status, equals(EventDomainStatus.liveActive));
      expect(domain.routeGeojson, isNotNull);

      final outJson = domain.toJson();
      expect(outJson['name'], equals('Cycling Rally 2026'));
      expect(outJson['type'], equals('CYCLING'));
    });

    test('SosEvent parses joined users and sub_groups relations', () {
      final json = {
        'id': 'sos-123',
        'domain_id': 'd1',
        'sender_user_id': 'u1',
        'active_sub_group_id': 'g1',
        'emergency_type': 'MEDICAL',
        'latitude': 21.1465,
        'longitude': 79.0882,
        'status': 'FORWARDED_TO_ADMIN',
        'leader_notes': 'Need stretcher at Law College',
        'created_at': '2026-08-14T07:15:00.000Z',
        'users': {'full_name': 'Priya Verma', 'phone_number': '+91 98240 11111'},
        'sub_groups': {'name': 'VNIT Cycling Club'},
      };

      final event = SosEvent.fromJson(json);
      expect(event.id, equals('sos-123'));
      expect(event.emergencyType, equals(EmergencyType.medical));
      expect(event.status, equals(SosStatus.forwardedToAdmin));
      expect(event.senderName, equals('Priya Verma'));
      expect(event.senderPhone, equals('+91 98240 11111'));
      expect(event.groupName, equals('VNIT Cycling Club'));
    });

    test('SosEvent parses disambiguated sender alias relation', () {
      final json = {
        'id': 'sos-456',
        'domain_id': 'd1',
        'sender_user_id': 'u2',
        'active_sub_group_id': 'g2',
        'emergency_type': 'BREAKDOWN',
        'latitude': 21.1500,
        'longitude': 79.0800,
        'status': 'TRIGGERED',
        'created_at': '2026-08-14T08:00:00.000Z',
        'sender': {'full_name': 'Rahul Deshmukh', 'phone_number': '+91 98220 33333'},
        'sub_groups': {'name': 'RCOEM Riders'},
      };

      final event = SosEvent.fromJson(json);
      expect(event.id, equals('sos-456'));
      expect(event.emergencyType, equals(EmergencyType.breakdown));
      expect(event.senderName, equals('Rahul Deshmukh'));
      expect(event.senderPhone, equals('+91 98220 33333'));
      expect(event.groupName, equals('RCOEM Riders'));
    });

    test('GroupMembership parses joined group relations and status', () {
      final json = {
        'id': 'm-123',
        'domain_id': 'd1',
        'group_id': 'g1',
        'user_id': 'u1',
        'is_active': true,
        'is_leader': true,
        'participation_status': 'CHECKED_IN',
        'checkin_time': '2026-08-14T06:15:00.000Z',
        'joined_at': '2026-08-14T05:00:00.000Z',
        'sub_groups': {'name': 'VNIT Cycling Club'},
      };

      final membership = GroupMembership.fromJson(json);
      expect(membership.isLeader, isTrue);
      expect(membership.isActive, isTrue);
      expect(membership.participationStatus, equals(ParticipationStatus.checkedIn));
      expect(membership.groupName, equals('VNIT Cycling Club'));
    });

    test('BroadcastMessage parses sender joined profile', () {
      final json = {
        'id': 'bc-1',
        'domain_id': 'd1',
        'sender_id': 'u-admin',
        'sender_role': 'SUPERADMIN',
        'target_type': 'GENERAL',
        'message_text': 'Flag-off at Zero Mile monument',
        'created_at': '2026-08-14T06:00:00.000Z',
        'users': {'full_name': 'Rajesh Sharma (Admin)'},
      };

      final msg = BroadcastMessage.fromJson(json);
      expect(msg.senderRole, equals(SenderRole.superAdmin));
      expect(msg.targetType, equals(BroadcastTargetType.general));
      expect(msg.senderName, equals('Rajesh Sharma (Admin)'));
    });
  });
}
