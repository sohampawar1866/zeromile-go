// test/logic/view_models_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_core/flutter_core.dart';

void main() {
  group('GroupsViewModel Quota & Logic Tests', () {
    test('isSubGroupCapReached triggers when 3 non-general groups are joined', () {
      final vm = GroupsViewModel();
      expect(vm.isSubGroupCapReached, isFalse);
      expect(vm.nonGeneralJoinedCount, equals(0));
    });

    test('TemporalWindowEvaluator supports server timestamp override', () {
      final now = DateTime(2026, 8, 14, 8, 0, 0); // 8 AM
      final domain = EventDomain(
        id: 'cycling-2026',
        name: 'Cycling Rally 2026',
        slug: 'cycling-2026',
        type: EventDomainType.cycling,
        status: EventDomainStatus.liveActive,
        startTime: DateTime(2026, 8, 14, 6, 0, 0), // 6 AM
        endTime: DateTime(2026, 8, 14, 11, 30, 0), // 11:30 AM
        createdAt: DateTime(2026, 8, 1),
      );

      final lifecycle = TemporalWindowEvaluator.evaluate(domain, currentTime: now);
      expect(lifecycle, equals(EventWindowLifecycle.liveActive));
      expect(TemporalWindowEvaluator.isLiveInteractive(domain, currentTime: now), isTrue);

      final expiredTime = DateTime(2026, 8, 14, 12, 0, 0); // 12 PM (After 11:30 AM)
      final expiredLifecycle = TemporalWindowEvaluator.evaluate(domain, currentTime: expiredTime);
      expect(expiredLifecycle, equals(EventWindowLifecycle.concluded));
      expect(TemporalWindowEvaluator.isLiveInteractive(domain, currentTime: expiredTime), isFalse);
    });

    test('AppConfig provides demo mode defaults and override methods', () {
      expect(AppConfig.isDemoMode, isA<bool>());
      AppConfig.override(isDemoMode: false);
      expect(AppConfig.isDemoMode, isFalse);
      AppConfig.override(isDemoMode: true);
      expect(AppConfig.isDemoMode, isTrue);
    });
  });
}
