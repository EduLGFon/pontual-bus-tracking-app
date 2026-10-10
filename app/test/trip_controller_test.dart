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

/// Gateway that always denies permission, for the denial path test.
class _DeniedGateway implements PermissionGateway {
  @override
  Future<LocationPermissionState> check() async =>
      LocationPermissionState.denied;

  @override
  Future<LocationPermissionState> request() async =>
      LocationPermissionState.denied;

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

TripController controller(
  MockClient client, {
  bool feed = true,
  PermissionGateway? gateway,
}) {
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
      gateway: gateway ?? FakeGateway(),
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
  if (feed) {
    // Feed one fix on the next microtask so starts observe it.
    scheduleMicrotask(() {
      positions.add(pos(-18.72, -39.85));
    });
  }
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

  test('no fix within the timeout reports noGps', () async {
    final TripController c = controller(happy(), feed: false);
    final bool started = await c.startTrip(
      lineId: 7,
      lineLabel: '7',
      showConsent: () async => true,
      showPermissions: () async {},
      firstFixTimeout: const Duration(milliseconds: 50),
    );
    expect(started, isFalse);
    expect(c.failReason, StartFailure.noGps);
    expect(c.state, isA<TripIdle>());
    c.dispose();
  });

  test('registration failure reports offline', () async {
    final MockClient client = MockClient((http.Request req) async {
      throw http.ClientException('unreachable');
    });
    final TripController c = controller(client);
    final bool started = await c.startTrip(
      lineId: 7,
      lineLabel: '7',
      showConsent: () async => true,
      showPermissions: () async {},
    );
    expect(started, isFalse);
    expect(c.failReason, StartFailure.offline);
    expect(c.state, isA<TripIdle>());
    c.dispose();
  });

  test('registration server error reports failed', () async {
    final MockClient client = MockClient((http.Request req) async {
      if (req.url.path == '/v1/devices') {
        return http.Response('{}', 500);
      }
      return http.Response('{}', 404);
    });
    final TripController c = controller(client);
    final bool started = await c.startTrip(
      lineId: 7,
      lineLabel: '7',
      showConsent: () async => true,
      showPermissions: () async {},
    );
    expect(started, isFalse);
    expect(c.failReason, StartFailure.failed);
    expect(c.state, isA<TripIdle>());
    c.dispose();
  });

  test('rate-limited start reports busy', () async {
    final MockClient client = MockClient((http.Request req) async {
      final String path = req.url.path;
      if (path == '/v1/devices') {
        return http.Response('{"token":"bm1_t","exp":1,"id":"d"}', 201);
      }
      if (path == '/v1/consents') {
        return http.Response('{"ok":true}', 200);
      }
      if (path == '/v1/trip') {
        return http.Response('{"e":"rate"}', 429);
      }
      return http.Response('{}', 404);
    });
    final TripController c = controller(client);
    final bool started = await c.startTrip(
      lineId: 7,
      lineLabel: '7',
      showConsent: () async => true,
      showPermissions: () async {},
    );
    expect(started, isFalse);
    expect(c.failReason, StartFailure.busy);
    c.dispose();
  });

  test('consent rejection clears the posted flag for a repost', () async {
    final MockClient client = MockClient((http.Request req) async {
      final String path = req.url.path;
      if (path == '/v1/devices') {
        return http.Response('{"token":"bm1_t","exp":1,"id":"d"}', 201);
      }
      if (path == '/v1/consents') {
        return http.Response('{"ok":true}', 200);
      }
      if (path == '/v1/trip') {
        return http.Response('{"e":"consent"}', 403);
      }
      return http.Response('{}', 404);
    });
    final TripController c = controller(client);
    final bool started = await c.startTrip(
      lineId: 7,
      lineLabel: '7',
      showConsent: () async => true,
      showPermissions: () async {},
    );
    expect(started, isFalse);
    expect(c.failReason, StartFailure.failed);
    expect(await const ConsentStore().readPosted(), isNull);
    c.dispose();
  });

  test('denied permission reports permission', () async {
    final TripController c = controller(happy(), gateway: _DeniedGateway());
    final bool started = await c.startTrip(
      lineId: 7,
      lineLabel: '7',
      showConsent: () async => true,
      showPermissions: () async {},
    );
    expect(started, isFalse);
    expect(c.failReason, StartFailure.permission);
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

  test('pings are paced to the server interval', () async {
    String? token;
    final FakeClock clock = FakeClock(100000);
    // ignore: close_sinks - closed at the end of the test.
    final StreamController<Position> positions =
        StreamController<Position>.broadcast();
    int pings = 0;
    final MockClient client = MockClient((http.Request req) async {
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
        pings += 1;
        return http.Response('{"r":"L","n":15}', 200);
      }
      return http.Response('{}', 404);
    });
    final TripController c = TripController(
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
          nowMs: () => clock.nowMs(),
        ),
        clock: clock,
      ),
    );
    Future<void> flush() async {
      for (int i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

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
    for (int i = 0; i < 100 && started == null; i++) {
      positions.add(pos(-18.72, -39.85));
      await Future<void>.microtask(() {});
    }
    expect(started, isTrue);
    // Start (n:20) arms the next slot 20 s out: an immediate fix is
    // tracked for health but sends nothing.
    positions.add(pos(-18.72, -39.85));
    await flush();
    expect(pings, 0);
    // At the slot the latest fix goes out exactly once.
    clock.advance(20000);
    positions.add(pos(-18.72, -39.85));
    await flush();
    expect(pings, 1);
    // The ping answer (n:15) re-arms the slot; early fixes wait.
    clock.advance(14000);
    positions.add(pos(-18.72, -39.85));
    await flush();
    expect(pings, 1);
    clock.advance(1000);
    positions.add(pos(-18.72, -39.85));
    await flush();
    expect(pings, 2);
    c.dispose();
    await positions.close();
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
