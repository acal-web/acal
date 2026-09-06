/// Configuration for the E2E suite, supplied at build time with `--dart-define`.
///
/// The defaults target an Android emulator talking to a Rails server on the
/// host (`10.0.2.2` is the emulator's alias for the host's localhost). Running
/// on Linux desktop, pass `--dart-define=API_BASE_URL=http://localhost:3000`.
library;

const e2eApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000',
);

const e2eAdminUsername = String.fromEnvironment(
  'E2E_ADMIN_USERNAME',
  defaultValue: 'e2e_admin',
);

const e2eAdminPassword = String.fromEnvironment(
  'E2E_ADMIN_PASSWORD',
  defaultValue: 'e2e_password123',
);
