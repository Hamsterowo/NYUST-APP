// cross_platform_pwa.dart
// This file acts as a facade.
export 'pwa_stub.dart' if (dart.library.js_interop) 'pwa_web.dart';
