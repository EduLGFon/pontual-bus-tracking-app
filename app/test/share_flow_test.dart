// Share-flow tests: the map entry opens consent, declining stays put,
// and /trip serves the started controller or the fallback. See PLAN.md
// S06 and S08.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/testing.dart';
import 'package:pontual/app/providers.dart';
import 'package:pontual/app/router.dart';
import 'package:pontual/data/config/remote_config.dart';
import 'package:pontual/data/static_data/static_data.dart';
import 'package:pontual/features/trip/share_flow.dart';
import 'package:pontual/features/trip/trip_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'trip_rig.dart';

/// Bundled flags for share-flow tests. The real provider loads config.json
/// through rootBundle, whose engine channel answers only the first
/// testWidgets per file and hangs later ones; literal JSON keeps these
/// tests hermetic. See DECISIONS.md T36 test note.
const String testBundleConfig =
    '{"min_app_version":"0.1.0","maintenance":false,"message_pt":"",'
    '"consent_version":1,"tile_url":"https://t.example/{z}/{x}/{y}.png"}';

/// Pilot line for share-flow tests.
const StaticLine pilotLine = StaticLine(
  id: 60,
  code: 'litoraneo',
  short: 'LIT',
  name: 'Litoraneo',
  pilot: true,
  schedules: <Map<String, dynamic>>[],
);

/// Non-pilot line: sharing must be a no-op.
const StaticLine regularLine = StaticLine(
  id: 61,
  code: 'regular',
  short: 'REG',
  name: 'Regular',
  pilot: false,
  schedules: <Map<String, dynamic>>[],
);

/// Pumps a button that starts the share flow for [line]. Remote flags come
/// from literal JSON (see above), never from rootBundle or the network.
Widget shareButton(StaticLine line) {
  final MutableGateway gateway = MutableGateway();
  final MockClient client = MockClient((_) async {
    throw StateError('no network in share-flow tests');
  });
  return ProviderScope(
    overrides: [
      remoteConfigRepoProvider.overrideWith(
        (Ref ref) async => RemoteConfigRepository(
          client: client,
          staticBaseUrl: () => 'https://static.example',
          bundleConfigJson: testBundleConfig,
          prefs: SharedPreferences.getInstance,
          nowMs: () => 0,
        ),
      ),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (BuildContext context) {
          return Consumer(
            builder: (BuildContext context, WidgetRef ref, _) {
              return FilledButton(
                onPressed: () =>
                    shareTrip(context, ref, line, gateway: gateway),
                child: const Text('share'),
              );
            },
          );
        },
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('share opens the consent sheet', (WidgetTester tester) async {
    await tester.pumpWidget(shareButton(pilotLine));
    await tester.tap(find.text('share'));
    await tester.pumpAndSettle();
    expect(find.text('Compartilhar sua localização'), findsOneWidget);
  });

  testWidgets('declining consent stays on the same screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(shareButton(pilotLine));
    await tester.tap(find.text('share'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Agora não'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Agora não'));
    await tester.pumpAndSettle();
    expect(find.text('Compartilhar sua localização'), findsNothing);
    expect(find.text('share'), findsOneWidget);
  });

  testWidgets('non-pilot lines never share', (WidgetTester tester) async {
    await tester.pumpWidget(shareButton(regularLine));
    await tester.tap(find.text('share'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Compartilhar sua localização'), findsNothing);
  });

  testWidgets('/trip with a controller shows the trip', (
    WidgetTester tester,
  ) async {
    final Rig r = rig(happy());
    await start(r);
    final GoRouter router = buildRouter();
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    router.go('/trip', extra: r.controller);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Compartilhando'), findsWidgets);
    // TripRoute owns the controller and disposes it with the tree.
    await r.positions.close();
  });

  testWidgets('/trip without a controller shows the fallback', (
    WidgetTester tester,
  ) async {
    final GoRouter router = buildRouter();
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    router.go('/trip');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(TripPlaceholder), findsOneWidget);
    expect(find.byType(TripScreen), findsNothing);
  });
}
