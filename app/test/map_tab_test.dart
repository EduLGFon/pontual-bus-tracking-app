// T28 tests: map tab states reachable in widget tests, TalkBack list,
// non-pilot note, recenter button.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pontual/app/providers.dart';
import 'package:pontual/app/strings_pt.dart';
import 'package:pontual/core/time/clock.dart';
import 'package:pontual/data/realtime/vehicle_repository.dart';
import 'package:pontual/data/static_data/static_data.dart';
import 'package:pontual/features/line/map_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'vehicle_test.dart' show FakeChannel;

const StaticLine pilot = StaticLine(
  id: 7,
  code: 'seven',
  short: '7',
  name: 'Seven',
  pilot: true,
  schedules: <Map<String, dynamic>>[],
);

const StaticLine nonPilot = StaticLine(
  id: 10,
  code: 'ten',
  short: '10',
  name: 'Ten',
  pilot: false,
  schedules: <Map<String, dynamic>>[],
);

const ClientVehicle bus = ClientVehicle(
  id: 3,
  lat: -18.72,
  lng: -39.85,
  heading: 90,
  kmh: 29,
  members: 1,
  ageS: 4,
);

/// Test harness holding the fakes for one map tab test.
class MapHarness {
  MapHarness(this.repo, this.channel);

  final VehicleRepository repo;
  final FakeChannel channel;

  MockClient get tiles => MockClient((_) async => http.Response('', 404));

  Future<void> pump(WidgetTester tester, StaticLine line) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleRepoProvider(7).overrideWithValue(repo),
          tileUrlProvider.overrideWithValue(
            const AsyncValue<String>.data('http://127.0.0.1:9/{z}/{x}/{y}.png'),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: MapTab(
              line: line,
              tileUrl: 'http://127.0.0.1:9/{z}/{x}/{y}.png',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    // Pump past the tab refresh tick so async start() results paint.
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  /// Tears down fakes. Fires without awaiting then pumps: the FakeAsync
  /// zone only flushes microtasks on pump.
  Future<void> dispose(WidgetTester tester) async {
    unawaited(repo.stop());
    unawaited(channel.dispose());
    await tester.pump();
    await tester.pump();
  }
}

MapHarness liveHarness() {
  final FakeChannel channel = FakeChannel();
  final VehicleRepository repo = VehicleRepository(
    fetchSnapshot: (_) async => const <ClientVehicle>[bus],
    openChannel: (_) async => channel,
    wsBaseUrl: () => 'ws://127.0.0.1:8080',
    clock: FakeClock(100000),
    launch: (Future<void> task) {},
  );
  return MapHarness(repo, channel);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('live state shows status, markers, and text rows', (
    WidgetTester tester,
  ) async {
    final MapHarness h = liveHarness();
    await h.pump(tester, pilot);
    await h.settle(tester);
    expect(find.textContaining('Ao vivo'), findsWidgets);
    expect(find.textContaining('Ônibus 1'), findsWidgets);
    await h.dispose(tester);
  });

  testWidgets('no vehicles shows the empty card', (WidgetTester tester) async {
    final FakeChannel channel = FakeChannel();
    final VehicleRepository repo = VehicleRepository(
      fetchSnapshot: (_) async => const <ClientVehicle>[],
      openChannel: (_) async => channel,
      wsBaseUrl: () => 'ws://127.0.0.1:8080',
      clock: FakeClock(100000),
      launch: (Future<void> task) {},
    );
    final MapHarness h = MapHarness(repo, channel);
    await h.pump(tester, pilot);
    await h.settle(tester);
    expect(find.textContaining('Nenhum ônibus'), findsOneWidget);
    expect(find.text(StringsPt.shareTrip), findsWidgets);
    await h.dispose(tester);
  });

  testWidgets('non-pilot line hides sharing with a note', (
    WidgetTester tester,
  ) async {
    final MapHarness h = liveHarness();
    await h.pump(tester, nonPilot);
    await h.settle(tester);
    expect(find.textContaining('ainda não tem rastreamento'), findsOneWidget);
    expect(find.text(StringsPt.shareTrip), findsNothing);
    await h.dispose(tester);
  });

  testWidgets('stale status appears with an old snapshot', (
    WidgetTester tester,
  ) async {
    final FakeClock clock = FakeClock(100000);
    final FakeChannel channel = FakeChannel();
    int calls = 0;
    final VehicleRepository repo = VehicleRepository(
      fetchSnapshot: (_) async {
        calls += 1;
        if (calls > 1) {
          throw StateError('network down');
        }
        return const <ClientVehicle>[bus];
      },
      openChannel: (_) async => channel,
      wsBaseUrl: () => 'ws://127.0.0.1:8080',
      clock: clock,
      launch: (Future<void> task) {},
    );
    final MapHarness h = MapHarness(repo, channel);
    await h.pump(tester, pilot);
    await h.settle(tester);
    clock.advance(60000);
    await h.settle(tester);
    expect(find.textContaining('Última posição'), findsOneWidget);
    await h.dispose(tester);
  });
}
