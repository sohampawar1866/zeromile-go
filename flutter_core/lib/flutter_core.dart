// lib/flutter_core.dart

/// ZeroMile Go - Core Data & Service Layer for Flutter
/// Modular Supabase Backend, Real-time WebSockets & OneSignal Push Integration

// Config
export 'config/app_config.dart';

// Models
export 'models/event_domain.dart';
export 'models/user_profile.dart';
export 'models/domain_superadmin.dart';
export 'models/sub_group.dart';
export 'models/group_membership.dart';
export 'models/group_creation_request.dart';
export 'models/broadcast_message.dart';
export 'models/sos_event.dart';
export 'models/user_live_location.dart';
export 'models/route_checkpoint.dart';

// Services
export 'services/supabase_client_service.dart';
export 'services/auth_service.dart';
export 'services/domain_service.dart';
export 'services/group_service.dart';
export 'services/sos_service.dart';
export 'services/location_telemetry_service.dart';
export 'services/broadcast_service.dart';
export 'services/push_notification_service.dart';

// Utils
export 'utils/density_cluster_evaluator.dart';
export 'utils/temporal_window_evaluator.dart';
