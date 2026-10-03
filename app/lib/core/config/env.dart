// Client environment. Values come from
// --dart-define-from-file=env/<env>.json and contain only API_BASE_URL and
// STATIC_BASE_URL. No secrets exist for clients. See PLAN.md 17.1.

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
