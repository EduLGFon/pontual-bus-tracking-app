// Client environment. Values come from
// --dart-define-from-file=env/<env>.json and contain only API_BASE_URL,
// STATIC_BASE_URL, and the optional FIX_ACCURACY_MAX_M test override.
// No secrets exist for clients. See PLAN.md 17.1.

/// Base URL of the Deno API.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8080',
);

/// Base URL of the static data host.
const String staticBaseUrl = String.fromEnvironment(
  'STATIC_BASE_URL',
  defaultValue: 'http://127.0.0.1:8080/data',
);

/// Maximum accepted fix accuracy in meters. Production default 60.
/// Easy-test phones set 500 to match a server running with
/// TEST_EASY_PUBLISH=true (which relaxes its own gate to 500).
const int fixAccuracyMaxM = int.fromEnvironment(
  'FIX_ACCURACY_MAX_M',
  defaultValue: 60,
);
