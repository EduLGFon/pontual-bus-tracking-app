// T23 tests: remote flags parsing, refresh rules, system screens.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pontual/core/errors/failures.dart';
import 'package:pontual/data/config/remote_config.dart';
import 'package:pontual/features/system/system_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String bundle =
    '{"min_app_version":"0.1.0","maintenance":false,"message_pt":"","consent_version":1,"tile_url":"https://t.example/{z}/{x}/{y}.png"}';

int nowMs = 0;

RemoteConfigRepository repo(MockClient client) {
  return RemoteConfigRepository(
    client: client,
    staticBaseUrl: () => 'https://static.example',
    bundleConfigJson: bundle,
    prefs: SharedPreferences.getInstance,
    nowMs: () => nowMs,
  );
}

void main() {
  setUp(() {
    nowMs = 0;
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('bundle flags load offline', () async {
    final MockClient client = MockClient((_) async {
      throw StateError('no network');
    });
    final RemoteConfig cfg = await repo(client).current();
    expect(cfg.maintenance, isFalse);
    expect(cfg.consentVersion, 1);
  });

  test('maintenance flag refreshes', () async {
    final RemoteConfigRepository r = repo(
      MockClient((_) async {
        return http.Response(
          '{"min_app_version":"0.1.0","maintenance":true,"message_pt":"Volta já","consent_version":1,"tile_url":"https://t.example/{z}/{x}/{y}.png"}',
          200,
        );
      }),
    );
    nowMs = remoteCheckInterval.inMilliseconds + 1;
    expect(((await r.refresh()) as Ok<bool>).value, isTrue);
    expect((await r.current()).messagePt, 'Volta já');
  });

  test('corrupt flags keep old values', () async {
    final RemoteConfigRepository r = repo(
      MockClient((_) async {
        return http.Response('nope', 200);
      }),
    );
    nowMs = remoteCheckInterval.inMilliseconds + 1;
    expect(await r.refresh(), isA<Err<bool>>());
    expect((await r.current()).maintenance, isFalse);
  });

  test('version comparison detects old builds', () {
    expect(RemoteConfig.updateRequired('0.1.0', '0.1.0'), isFalse);
    expect(RemoteConfig.updateRequired('0.1.0', '0.2.0'), isTrue);
    expect(RemoteConfig.updateRequired('1.0.0', '0.9.9'), isFalse);
  });

  testWidgets('system screens show per-kind titles', (
    WidgetTester tester,
  ) async {
    for (final SystemKind kind in SystemKind.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: SystemScreen(kind: kind, message: 'Oi'),
        ),
      );
      expect(find.text('Oi'), findsOneWidget);
    }
    await tester.pumpWidget(
      const MaterialApp(home: SystemScreen(kind: SystemKind.maintenance)),
    );
    expect(find.text('Em manutenção'), findsOneWidget);
  });

  testWidgets('offline banner announces saved data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: OfflineBanner()));
    expect(find.text('Sem conexão. Mostrando dados salvos.'), findsOneWidget);
  });
}
