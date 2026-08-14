// test/utils/temporal_window_evaluator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_core/flutter_core.dart';

void main() {
  group('TemporalWindowEvaluator Tests', () {
    test('evaluate returns liveActive when current time is within active rally schedule', () {
      final domain = EventDomain(
        id: 'cycling-2026',
        name: 'Cycling Rally 2026',
        slug: 'cycling-2026',
        type: EventDomainType.cycling,
        status: EventDomainStatus.liveActive,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(hours: 3)),
        createdAt: DateTime.now(),
      );

      final lifecycle = TemporalWindowEvaluator.evaluate(domain);
      expect(lifecycle, equals(EventWindowLifecycle.liveActive));
      expect(TemporalWindowEvaluator.isLiveInteractive(domain), isTrue);

      final banner = TemporalWindowEvaluator.getScheduleBanner(domain);
      expect(banner, contains('LIVE RALLY ACTIVE'));
    });

    test('evaluate returns preEvent when event is upcoming or before start time', () {
      final domain = EventDomain(
        id: 'marathon-2026',
        name: 'Nagpur Marathon',
        slug: 'marathon-2026',
        type: EventDomainType.marathon,
        status: EventDomainStatus.upcoming,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 5)),
        createdAt: DateTime.now(),
      );

      final lifecycle = TemporalWindowEvaluator.evaluate(domain);
      expect(lifecycle, equals(EventWindowLifecycle.preEvent));
      expect(TemporalWindowEvaluator.isLiveInteractive(domain), isFalse);

      final banner = TemporalWindowEvaluator.getScheduleBanner(domain);
      expect(banner, contains('PRE-EVENT PREPARATION'));
    });

    test('evaluate returns concluded when status is concluded or after end time', () {
      final domain = EventDomain(
        id: 'walkathon-2026',
        name: 'Walkathon',
        slug: 'walkathon-2026',
        type: EventDomainType.walkathon,
        status: EventDomainStatus.concluded,
        startTime: DateTime.now().subtract(const Duration(days: 2)),
        endTime: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now(),
      );

      final lifecycle = TemporalWindowEvaluator.evaluate(domain);
      expect(lifecycle, equals(EventWindowLifecycle.concluded));
      expect(TemporalWindowEvaluator.isLiveInteractive(domain), isFalse);

      final banner = TemporalWindowEvaluator.getScheduleBanner(domain);
      expect(banner, contains('EVENT CONCLUDED'));
    });
  });
}
