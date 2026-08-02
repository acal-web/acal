class AppConfig {
  static const String appName = 'Acal';

  // Baked in at build time via `--dart-define=API_BASE_URL=...` (see app/Dockerfile).
  // Defaults to localhost for local dev, where no dart-define is passed.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}