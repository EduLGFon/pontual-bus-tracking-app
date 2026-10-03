// T34 widget tests: offline status and the RF16 walking dialog on the
// S08 trip screen. See PLAN.md S08 and RF16.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pontual/domain/trip/auto_end.dart';
import 'package:pontual/features/trip/trip_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'trip_rig.dart';

/// HTTP double where pings hang until [hanging] completes.
MockClient hangingClient(Completer<http.Response> hanging) {
  return MockClient((http.Request req) async {
    final String path = req.url.path;
    if (path == '/v1/devices') {
      return http.Response('{"token":"bm1_t","exp":1,"id":"d"}', 201);
    }
    if (path == '/v1/consents') {
      return http.Response('{"ok":true}', 200);
    }
    if (path == '/v1/trip' && req.method == 'POST') {
      return http.Response('{"r":"W","n":20}', 201);
    }
    if (path == '/v1/trip/ping') {
      return hanging.future;
    }
    return http.Response('', 204);
  });
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('offline trip shows the retry status', (
    WidgetTester tester,
  ) async {
    final Completer<http.Response> hanging = Completer<http.Response>();
    final Rig r = rig(hangingClient(hanging));
    bool? started;
    unawaited(
      r.controller
          .startTrip(
            lineId: 7,
            lineLabel: '7',
            showConsent: () async => true,
            showPermissions: () async {},
          )
          .then((bool v) => started = v),
    );
    await tester.pumpWidget(
      MaterialApp(home: TripScreen(controller: r.controller)),
    );
    for (int i = 0; i < 30 && started == null; i++) {
      r.positions.add(pos(8));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(started, isTrue);
    r.positions.add(pos(8));
    await tester.pump(const Duration(milliseconds: 100));
    r.clock.advance(121 * 1000);
    await r.controller.checkAutoEndForTest();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Sem conexão'), findsWidgets);
    hanging.complete(http.Response('{"r":"F","n":90}', 200));
    for (int i = 0; i < 50 && r.controller.isOffline; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(r.controller.isOffline, isFalse);
    r.controller.dispose();
    await r.positions.close();
  });

  testWidgets('walking dialog confirms still riding', (
    WidgetTester tester,
  ) async {
    final Rig r = rig(happy());
    bool? started;
    unawaited(
      r.controller
          .startTrip(
            lineId: 7,
            lineLabel: '7',
            showConsent: () async => true,
            showPermissions: () async {},
          )
          .then((bool v) => started = v),
    );
    await tester.pumpWidget(
      MaterialApp(home: TripScreen(controller: r.controller)),
    );
    for (int i = 0; i < 30 && started == null; i++) {
      r.positions.add(pos(8));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(started, isTrue);
    r.controller.onFixForTest(fix(0));
    r.clock.advance(walkingPromptAfterMs + 1000);
    r.controller.onFixForTest(fix(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Você ainda está no ônibus?'), findsOneWidget);
    await tester.tap(find.text('Sim, continuar'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(r.controller.walkingPromptVisible, isFalse);
    r.controller.dispose();
    await r.positions.close();
  });
}
