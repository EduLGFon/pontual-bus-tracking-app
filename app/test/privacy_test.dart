// T41 tests: collection summary, revoke and delete actions, offline
// honesty, and the end-to-end delete navigation.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pontual/app/providers.dart';
import 'package:pontual/data/api/bus_api.dart';
import 'package:pontual/data/prefs/consent_store.dart';
import 'package:pontual/data/prefs/theme_store.dart';
import 'package:pontual/data/prefs/token_store.dart';
import 'package:pontual/features/settings/privacy_actions.dart';
import 'package:pontual/features/settings/privacy_screen.dart';
import 'package:pontual/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API double answering delete and trip-end calls.
BusApi apiFor(Future<http.Response> Function(http.Request) handler) {
  String? token;
  return BusApi(
    client: MockClient(handler),
    baseUrl: () => 'http://127.0.0.1:8080',
    readToken: () async => token,
    writeToken: (String t) async => token = t,
  );
}

void main() {
  group('PrivacyActions', () {
    test('delete clears token and prefs when online', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        tokenPrefsKey: 'bm1_x',
        consentVersionKey: 1,
        themeModeKey: 'dark',
      });
      final PrivacyActions actions = PrivacyActions(
        api: apiFor((http.Request req) async {
          if (req.url.path == '/v1/me') {
            return http.Response('', 204);
          }
          return http.Response('{}', 404);
        }),
      );
      expect(await actions.deleteMyData(), DeleteOutcome.deleted);
      expect(await const TokenStore().read(), isNull);
      expect(await const ConsentStore().read(), isNull);
    });

    test('delete without a token just clears local data', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        consentVersionKey: 1,
      });
      final PrivacyActions actions = PrivacyActions(
        api: apiFor((_) async => http.Response('{}', 500)),
      );
      expect(await actions.deleteMyData(), DeleteOutcome.deleted);
      expect(await const ConsentStore().read(), isNull);
    });

    test('offline delete keeps everything', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        tokenPrefsKey: 'bm1_x',
        consentVersionKey: 1,
      });
      final PrivacyActions actions = PrivacyActions(
        api: apiFor((_) async => http.Response('{}', 503)),
      );
      expect(await actions.deleteMyData(), DeleteOutcome.offline);
      expect(await const TokenStore().read(), 'bm1_x');
      expect(await const ConsentStore().read(), 1);
    });

    test('revoke clears consent and ends the trip best-effort', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        tokenPrefsKey: 'bm1_x',
        consentVersionKey: 1,
      });
      bool ended = false;
      final PrivacyActions actions = PrivacyActions(
        api: apiFor((http.Request req) async {
          if (req.url.path == '/v1/trip') {
            ended = true;
            return http.Response('', 204);
          }
          return http.Response('{}', 404);
        }),
      );
      await actions.revokeConsent();
      expect(ended, isTrue);
      expect(await const ConsentStore().read(), isNull);
    });
  });

  group('PrivacyScreen', () {
    testWidgets('shows summary, rows, and policy text', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: PrivacyScreen())),
      );
      expect(find.text('Política de Privacidade'), findsOneWidget);
      expect(find.text('Termos de Uso'), findsOneWidget);
      expect(find.text('O que coletamos'), findsOneWidget);
      expect(find.textContaining('Sem histórico'), findsOneWidget);
      expect(find.text('Apagar meus dados'), findsOneWidget);
      expect(find.text('Revogar consentimento'), findsOneWidget);
    });

    testWidgets('cancel keeps the token', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        tokenPrefsKey: 'bm1_x',
      });
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: PrivacyScreen())),
      );
      await tester.tap(find.text('Apagar meus dados'));
      await tester.pumpAndSettle();
      expect(find.text('Apagar meus dados?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(await const TokenStore().read(), 'bm1_x');
    });

    testWidgets('delete end-to-end returns to welcome', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        tokenPrefsKey: 'bm1_x',
      });
      final BusApi api = apiFor((http.Request req) async {
        if (req.url.path == '/v1/me') {
          return http.Response('', 204);
        }
        return http.Response('{}', 404);
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [busApiProvider.overrideWithValue(api)],
          child: const PontualApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Começar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Privacidade e dados'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apagar meus dados'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apagar'));
      await tester.pumpAndSettle();
      expect(find.text('Acompanhe o ônibus ao vivo'), findsOneWidget);
      expect(await const TokenStore().read(), isNull);
    });
  });
}
