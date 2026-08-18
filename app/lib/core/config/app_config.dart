import 'app_config_io.dart' if (dart.library.js_interop) 'app_config_web.dart' as platform;

class AppConfig {
  static const String appName = '';
  static String get apiBaseUrl => platform.apiBaseUrl;
}
