// T33 tests: controller solo ride on fakes plus end-card copy.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pontual/core/time/clock.dart';
import 'package:pontual/data/api/bus_api.dart';
import 'package:pontual/data/prefs/consent_store.dart';
import 'package:pontual/domain/trip/trip_state.dart';
import 'package:pontual/features/trip/location_service.dart';
import 'package:pontual/features/trip/permission_sheet.dart';
import 'package:pontual/features/trip/trip_controller.dart';
import 'package:pontual/features/trip/trip_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeGateway implements PermissionGateway {
  @override
  Future<LocationPermissionState> check() async =>
      LocationPermissionState.granted;

  @override
  Future<LocationPermissionState> request() async =>
      LocationPermissionState.granted;

  @override
  Future<bool> servicesOn() async => true;

  @override
  Future<void> openSettings() async {}
}

Position pos(double lat, double lng) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime.fromMillisecondsSinceEpoch(100000),
    accuracy: 10,
    altitude: 0,
    heading: 90,
    speed: 8,
    speedAccuracy: 1,
    altitudeAccuracy: 1,
    headingAccuracy: 1,
  );
}

TripController controller(MockClient client) {
  String? token;
  // ignore: close_sinks - single buffered test event; the service owns it.
  final StreamController<Position> positions = StreamController<Position>();
  final TripController controller = TripController(
    TripDeps(
      api: BusApi(
        client: client,
        baseUrl: () => 'http://127.0.0.1:8080',
        readToken: () async => token,
        writeToken: (String t) async => token = t,
      ),
      gateway: FakeGateway(),
      consentStore: const ConsentStore(),
      consentVersion: 1,
      locations: () => LocationService(
        positionStream: (_) => positions.stream,
        batteryLevel: () async => 80,
        charging: () async => false,
        nowMs: () => 100000,
      ),
      clock: FakeClock(100000),
    ),
  );
  // Feed one fix on the next microtask so starts observe it.
  scheduleMicrotask(() {
    positions.add(pos(-18.72, -39.85));
  });
  return controller;
}

MockClient happy() {
  return MockClient((http.Request req) async {
    final String path = req.url.path;
    if (path == '/v1/devices') {
      return http.Response('{"token":"bm1_t","exp":1,"id":"d"}', 201);
    }
    if (path == '/v1/consents') {
      return http.Response('{"ok":true}', 200);
    }
    if (path == '/v1/trip') {
      if (req.method == 'DELETE') {
        return http.Response('', 204);
      }
      return http.Response('{"r":"W","n":20}', 201);
    }
    if (path == '/v1/trip/ping') {
      return http.Response('{"r":"L","n":15}', 200);
    }
    return http.Response('{}', 404);
  });
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('solo ride: consent to active to user end', () async {
    final TripController c = controller(happy());
    final bool started = await c.startTrip(
      lineId: 7,
      lineLabel: '7',
      showConsent: () async => true,
      showPermissions: () async {},
    );
    expect(started, isTrue);
    for (int i = 0; i < 50 && c.state is! TripActive; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(c.state, isA<TripActive>());
    await c.endTrip();
    expect(c.state, isA<TripIdle>());
    expect(c.endKind, TripEndKind.user);
    c.dispose();
  });

  test('declined consent never touches the network', () async {
    int calls = 0;
    final MockClient client = MockClient((_) async {
      calls += 1;
      return http.Response('', 500);
    });
    final TripController c = controller(client);
    final bool started = await c.startTrip(
      lineId: 7,
      lineLabel: '7',
      showConsent: () async => false,
      showPermissions: () async {},
    );
    expect(started, isFalse);
    expect(calls, 0);
    expect(c.state, isA<TripIdle>());
    c.dispose();
  });

  testWidgets('trip screen shows sharing state', (WidgetTester tester) async {
    final TripController c = controller(happy());
    // Kick off without awaiting: each async hop needs pump rounds to flush
    // the fix stream the start is waiting for.
    bool? started;
    unawaited(
      c
          .startTrip(
            lineId: 7,
            lineLabel: '7',
            showConsent: () async => true,
            showPermissions: () async {},
          )
          .then((bool v) => started = v),
    );
    await tester.pumpWidget(MaterialApp(home: TripScreen(controller: c)));
    for (int i = 0; i < 30 && started == null; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(started, isTrue);
    expect(find.textContaining('Compartilhando'), findsWidgets);
    await c.endTrip();
    await tester.pump(const Duration(milliseconds: 100));
    c.dispose();
  });

  testWidgets('end cards carry each reason', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EndCard(kind: TripEndKind.automatic, detail: 'idle'),
      ),
    );
    expect(find.textContaining('parado por 10 minutos'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(home: EndCard(kind: TripEndKind.abuse)),
    );
    expect(find.textContaining('inconsistentes'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(home: EndCard(kind: TripEndKind.user)),
    );
    expect(find.text('Voltar às linhas'), findsOneWidget);
  });
}
