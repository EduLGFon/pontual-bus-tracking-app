// T20 tests: lazy registration, one per install, token reuse.
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pontual/core/errors/failures.dart';
import 'package:pontual/data/api/bus_api.dart';
import 'package:pontual/data/net/http_client.dart';

void main() {
  test('constructing the API performs no requests', () async {
    int calls = 0;
    final MockClient client = MockClient((_) async {
      calls += 1;
      return http.Response('{}', 201);
    });
    BusApi(
      client: client,
      baseUrl: () => 'http://127.0.0.1:8080',
      readToken: () async => null,
      writeToken: (_) async {},
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(calls, 0);
  });

  test('registers once then reuses the stored token', () async {
    int calls = 0;
    String? stored;
    final MockClient client = MockClient((_) async {
      calls += 1;
      return http.Response('{"token":"bm1_x","exp":1,"id":"d"}', 201);
    });
    final BusApi api = BusApi(
      client: client,
      baseUrl: () => 'http://127.0.0.1:8080',
      readToken: () async => stored,
      writeToken: (String t) async => stored = t,
    );
    final Result<String> first = await api.ensureRegistered();
    final Result<String> second = await api.ensureRegistered();
    expect(calls, 1);
    expect(stored, 'bm1_x');
    expect(first, isA<Ok<String>>());
    expect(second, isA<Ok<String>>());
  });

  test('server errors map to failures', () async {
    final MockClient client = MockClient((_) async {
      return http.Response('{"e":"rate"}', 429);
    });
    final BusApi api = BusApi(
      client: client,
      baseUrl: () => 'http://127.0.0.1:8080',
      readToken: () async => null,
      writeToken: (_) async {},
    );
    final Result<String> result = await api.ensureRegistered();
    expect(result, isA<Err<String>>());
  });

  test('shared client factory builds without network', () {
    final http.Client client = createHttpClient();
    client.close();
  });
}
