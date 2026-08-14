// lib/utils/temporal_window_evaluator.dart

import '../models/event_domain.dart';

enum EventWindowLifecycle { preEvent, liveActive, concluded }

class TemporalWindowEvaluator {
  /// Evaluates whether the event is within the official active rally hours
  static EventWindowLifecycle evaluate(EventDomain domain) {
    final now = DateTime.now();

    if (domain.status == EventDomainStatus.concluded ||
        domain.status == EventDomainStatus.archived ||
        now.isAfter(domain.endTime)) {
      return EventWindowLifecycle.concluded;
    } else if (domain.status == EventDomainStatus.liveActive &&
        now.isAfter(domain.startTime) &&
        now.isBefore(domain.endTime)) {
      return EventWindowLifecycle.liveActive;
    } else if (now.isBefore(domain.startTime) || domain.status == EventDomainStatus.upcoming) {
      return EventWindowLifecycle.preEvent;
    }
    return EventWindowLifecycle.preEvent;
  }

  /// Whether GPS tracking, live map streaming, and SOS trigger should be fully active
  static bool isLiveInteractive(EventDomain domain) {
    return evaluate(domain) == EventWindowLifecycle.liveActive;
  }

  /// Human-readable schedule banner text
  static String getScheduleBanner(EventDomain domain) {
    final lifecycle = evaluate(domain);
    switch (lifecycle) {
      case EventWindowLifecycle.preEvent:
        return '🏁 PRE-EVENT PREPARATION • Live GPS & SOS activates at ${_formatTime(domain.startTime)}';
      case EventWindowLifecycle.liveActive:
        return '🟢 LIVE RALLY ACTIVE • Real-time GPS Tracking, Muster & SOS Online';
      case EventWindowLifecycle.concluded:
        return '🏁 EVENT CONCLUDED • Static route preview & certificate downloads open';
    }
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $ampm';
  }
}
