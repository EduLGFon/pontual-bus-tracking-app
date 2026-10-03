// BusApi base: typed HTTP over the shared client with the bearer token.
// Registration happens on demand only when sharing starts: at most one
// registration per install. No request fires at startup or first paint.
// See PLAN.md 8.4 and 6.5.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pontual/core/errors/failures.dart';
import 'package:pontual/data/net/http_client.dart';

/// Base URL provider, injectable for tests.
typedef BaseUrlProvider = String Function();

/// Minimal API surface for T20: registration on demand.
class BusApi {
  /// Creates an API client. Performs no network calls.
  BusApi({
    required this.client,
    required this.baseUrl,
    required this.readToken,
    required this.writeToken,
  });

  /// Shared keep-alive HTTP client.
  final http.Client client;

  /// API base URL provider.
  final BaseUrlProvider baseUrl;

  /// Reads the stored device token.
  final Future<String?> Function() readToken;

  /// Persists the device token.
  final Future<void> Function(String token) writeToken;

  String? _cachedToken;

  /// Returns the device token, registering once per install when needed.
  /// Callers outside trip sharing never invoke this.
  Future<Result<String>> ensureRegistered() async {
    final String? cached = _cachedToken ?? await readToken();
    if (cached != null && cached.isNotEmpty) {
      _cachedToken = cached;
      return Ok<String>(cached);
    }
    try {
      final http.Response res = await client
          .post(
            Uri.parse('${baseUrl()}/v1/devices'),
            headers: <String, String>{'content-type': 'application/json'},
            body: '{}',
          )
          .timeout(requestTimeout);
      if (res.statusCode != 201) {
        return const Err<String>(ServerFailure('register failed', 'register'));
      }
      final Map<String, dynamic> body =
          jsonDecode(res.body) as Map<String, dynamic>;
      final String? token = body['token'] as String?;
      if (token == null || token.isEmpty) {
        return const Err<String>(ServerFailure('bad token', 'register'));
      }
      await writeToken(token);
      _cachedToken = token;
      return Ok<String>(token);
    } on TimeoutException {
      return const Err<String>(NetworkFailure('register timed out'));
    } on http.ClientException catch (e) {
      return Err<String>(NetworkFailure(e.message));
    }
  }
}
