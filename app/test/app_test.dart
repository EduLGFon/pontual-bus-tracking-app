// T18 router and scale tests. Screens are navigable and survive 200
// percent text scale on a narrow screen without clipping errors.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pontual/app/providers.dart';
import 'package:pontual/app/strings_pt.dart';
import 'package:pontual/data/static_data/static_data.dart';
import 'package:pontual/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps the app with a scope, mirroring main.dart.
Future<void> pumpApp(WidgetTester tester, Widget child) {
  return tester.pumpWidget(ProviderScope(child: child));
}

/// Pumps the full app with deterministic line data. Widget tests must not
/// depend on rootBundle or the network: asset loads answer once per file
/// and remote fetches are blocked by CORS on `flutter test --platform
/// chrome`, so navigation targets would stay empty there.
Future<void> pumpAppWithLines(WidgetTester tester) {
  final MockClient httpClient = MockClient((http.Request req) async {
    return http.Response('[]', 200);
  });
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        httpClientProvider.overrideWithValue(httpClient),
        linesProvider.overrideWith(
          (Ref ref) async => StaticDataRepository(
            client: httpClient,
            staticBaseUrl: () => 'https://x.example',
            bundleManifestJson: '{}',
            bundleLinesJson:
                '[{"id":60,"code":"sixty","short":"60","name":"Litoraneo",'
                '"pilot":true,"schedules":[]}]',
            prefs: SharedPreferences.getInstance,
            nowMs: () => 0,
          ).lines(),
        ),
      ],
      child: const PontualApp(),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('boots on welcome with pt-BR copy', (WidgetTester tester) async {
    await pumpApp(tester, const PontualApp());
    await tester.pumpAndSettle();
    expect(find.text(StringsPt.welcomeTitle), findsOneWidget);
    expect(find.text(StringsPt.start), findsOneWidget);
  });

  testWidgets('welcome navigates home', (WidgetTester tester) async {
    await pumpAppWithLines(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text(StringsPt.start));
    await tester.pumpAndSettle();
    expect(find.text(StringsPt.homeAllLines), findsOneWidget);
  });

  testWidgets('survives 200 percent text scale', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(2),
            size: Size(360, 640),
          ),
          child: PontualApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
