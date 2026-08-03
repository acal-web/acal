import 'app_config_io.dart' if (dart.library.js_interop) 'app_config_web.dart' as platform;

class AppConfig {
  static const String appName = 'Acal';

  /// On web this reads `window.API_BASE_URL`, set at container start from a
  /// real env var (see app/Dockerfile) — the same image works in any
  /// environment. On mobile/desktop, where there is no "container runtime"
  /// to inject that, it falls back to a build-time `--dart-define`.
  static String get apiBaseUrl => platform.apiBaseUrl;
}
