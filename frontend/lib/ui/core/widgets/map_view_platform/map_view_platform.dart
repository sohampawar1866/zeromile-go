// lib/ui/core/widgets/map_view_platform/map_view_platform.dart

export 'map_view_platform_mobile.dart'
    if (dart.library.js_interop) 'map_view_platform_web.dart'
    if (dart.library.html) 'map_view_platform_web.dart';
