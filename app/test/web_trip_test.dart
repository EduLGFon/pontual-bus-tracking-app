// T38 web sharing tests: visibility pause policy, wake lock fake, the
// controller hidden flag, and the always-visible web banner.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pontual/platform/web/visibility.dart';
import 'package:pontual/platform/web/wake_lock.dart';
import 'package:pontual/platform/web/web_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'trip_rig.dart';

void main() {
  group('webShouldPause', () {
    test('pauses at 60 s, not before', () {
      expect(webShouldPause(59999), isFalse);
      expect(webShouldPause(60000), isTrue);
      expect(webShouldPause(120000), isTrue);
    });
  });

  group('WebVisibilityTracker', () {
    test('visible by default, never pauses', () {
      final WebVisibilityTracker tracker = WebVisibilityTracker();
      tracker.check(1000000);
      expect(tracker.paused, isFalse);
      expect(tracker.hiddenFor(1000000), 0);
    });

    test('short hide does not pause, long hide does', () {
      final WebVisibilityTracker tracker = WebVisibilityTracker();
      tracker.onHidden(0);
      tracker.check(59999);
      expect(tracker.paused, isFalse);
      tracker.check(60000);
      expect(tracker.paused, isTrue);
    });

    test('visible clears the pause', () {
      final WebVisibilityTracker tracker = WebVisibilityTracker();
      tracker.onHidden(0);
      tracker.check(90000);
      expect(tracker.paused, isTrue);
      tracker.onVisible();
      expect(tracker.paused, isFalse);
      tracker.check(200000);
      expect(tracker.paused, isFalse);
    });

    test('repeated hidden keeps the first timestamp', () {
      final WebVisibilityTracker tracker = WebVisibilityTracker();
      tracker.onHidden(1000);
      tracker.onHidden(50000);
      expect(tracker.hiddenFor(61000), 60000);
    });
  });

  group('FakeWebWakeLock', () {
    test('tracks enable and disable', () async {
      final FakeWebWakeLock lock = FakeWebWakeLock();
      expect(await lock.enabled, isFalse);
      await lock.enable();
      expect(await lock.enabled, isTrue);
      expect(lock.enables, 1);
      await lock.disable();
      expect(await lock.enabled, isFalse);
      expect(lock.disables, 1);
    });
  });

  group('TripController web hidden', () {
    test('flag toggles and notifies, drops fixes while hidden', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final Rig r = rig(happy());
      await start(r);
      expect(r.controller.isWebHidden, isFalse);
      int notified = 0;
      r.controller.addListener(() {
        notified += 1;
      });
      r.controller.setWebHidden(true);
      expect(r.controller.isWebHidden, isTrue);
      expect(notified, 1);
      r.controller.setWebHidden(true);
      expect(notified, 1);
      r.controller.setWebHidden(false);
      expect(r.controller.isWebHidden, isFalse);
      addTearDown(() async {
        await r.controller.endTrip();
        r.controller.dispose();
        await r.positions.close();
      });
    });
  });

  group('WebTripBanner', () {
    testWidgets('shows the keep-open text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: WebTripBanner())),
      );
      expect(find.textContaining('Mantenha esta tela aberta'), findsOneWidget);
      expect(find.textContaining('brilho'), findsOneWidget);
    });

    testWidgets('paused and unsupported lines appear on demand', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WebTripBanner(paused: true, wakeUnsupported: true),
          ),
        ),
      );
      expect(find.textContaining('Tela oculta'), findsOneWidget);
      expect(find.textContaining('não mantém a tela ligada'), findsOneWidget);
    });
  });
}
