// T24 tests: home search, list, and live indicators with overridden
// providers. No spinners appear on cached content.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pontual/app/providers.dart';
import 'package:pontual/app/strings_pt.dart';
import 'package:pontual/data/api/bus_api.dart';
import 'package:pontual/data/api/dto.dart';
import 'package:pontual/data/static_data/static_data.dart';
import 'package:pontual/features/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String linesJson =
    '[{"id":60,"code":"sixty","short":"60","name":"Litoraneo","pilot":true,"schedules":[]},'
    '{"id":62,"code":"sixtytwo","short":"62","name":"Guriri","pilot":true,"schedules":[]}]';

Widget homeWith({required String liveBody}) {
  final MockClient httpClient = MockClient((http.Request req) async {
    if (req.url.path == '/v1/live') {
      return http.Response(liveBody, 200);
    }
    return http.Response('[]', 200);
  });
  return ProviderScope(
    overrides: [
      httpClientProvider.overrideWithValue(httpClient),
      linesProvider.overrideWith(
        (Ref ref) async => StaticDataRepository(
          client: httpClient,
          staticBaseUrl: () => 'https://x.example',
          bundleManifestJson: '{}',
          bundleLinesJson: linesJson,
          prefs: SharedPreferences.getInstance,
          nowMs: () => 0,
        ).lines(),
      ),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('lists cached lines with no spinners', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(homeWith(liveBody: '[]'));
    await tester.pumpAndSettle();
    expect(find.text('Litoraneo'), findsOneWidget);
    expect(find.text('Guriri'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(StringsPt.homeUnofficial), findsOneWidget);
  });

  testWidgets('live dots appear from live lines', (WidgetTester tester) async {
    await tester.pumpWidget(homeWith(liveBody: '[[60,2]]'));
    await tester.pumpAndSettle();
    expect(find.text(StringsPt.homeLiveNow), findsOneWidget);
    expect(find.text('Ao vivo'), findsWidgets);
    expect(find.text('2 ônibus ao vivo'), findsWidgets);
    expect(find.text(StringsPt.homeTimetableOnly), findsOneWidget);
  });

  testWidgets('search filters locally', (WidgetTester tester) async {
    await tester.pumpWidget(homeWith(liveBody: '[]'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'gur');
    await tester.pumpAndSettle();
    expect(find.text('Guriri'), findsOneWidget);
    expect(find.text('Litoraneo'), findsNothing);
  });

  test('live provider falls back to empty on errors', () async {
    final MockClient failing = MockClient((_) async {
      return http.Response('boom', 500);
    });
    final ProviderContainer container = ProviderContainer(
      overrides: [
        httpClientProvider.overrideWithValue(failing),
        busApiProvider.overrideWith(
          (Ref ref) => BusApi(
            client: failing,
            baseUrl: () => 'https://x.example',
            readToken: () async => null,
            writeToken: (_) async {},
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final LiveLines live = await container.read(liveProvider.future);
    expect(live.rows, isEmpty);
  });
}
