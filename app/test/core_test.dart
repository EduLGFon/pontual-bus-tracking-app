// Core unit tests: Clock, Log, geo helpers, backoff, Result/failures.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pontual/core/errors/failures.dart';
import 'package:pontual/core/geo/geo.dart';
import 'package:pontual/core/logging/log.dart';
import 'package:pontual/core/net/backoff.dart';
import 'package:pontual/core/time/clock.dart';

void main() {
  group('FakeClock', () {
    test('starts at zero and advances', () {
      final FakeClock clock = FakeClock();
      expect(clock.nowMs(), 0);
      clock.advance(1500);
      expect(clock.nowMs(), 1500);
      expect(clock.monotonicMs(), 1500);
    });

    test('system clock moves forward', () {
      final SystemClock clock = SystemClock();
      final int first = clock.monotonicMs();
      expect(clock.nowMs(), greaterThan(0));
      expect(clock.monotonicMs(), greaterThanOrEqualTo(first));
    });
  });

  group('Log', () {
    test('keeps warnings and errors in a bounded ring', () {
      Log.clearForTest();
      Log.w('low battery', 'route=trip');
      Log.e('ping failed', 'status=500');
      Log.d('trace');
      Log.i('hello');
      expect(Log.recent.length, 2);
      expect(Log.recent.first.message, 'low battery');
      for (int i = 0; i < 250; i++) {
        Log.e('flood $i');
      }
      expect(Log.recent.length, 200);
    });
  });

  group('geo', () {
    test('haversine matches a known distance', () {
      // About 111.2 m per 0.001 degrees of latitude.
      expect(distM(-18.72, -39.85, -18.719, -39.85), closeTo(111.2, 0.5));
    });

    test('bbox contains its interior only', () {
      const BBox box = BBox(
        latMin: -19.05,
        latMax: -18.40,
        lngMin: -40.25,
        lngMax: -39.55,
      );
      expect(box.contains(-18.72, -39.85), isTrue);
      expect(box.contains(-20, -39.85), isFalse);
      expect(box.contains(-18.72, -41), isFalse);
    });

    test('polyline decodes a known string', () {
      // Canonical example from the polyline format reference.
      final List<LatLng> pts = decodePolyline('_p~iF~ps|U', 5);
      expect(pts.length, 1);
      expect(pts.first.lat, closeTo(38.5, 1e-5));
      expect(pts.first.lng, closeTo(-120.2, 1e-5));
    });
  });

  group('Backoff', () {
    test('follows the ladder with bounded jitter', () {
      final Backoff backoff = Backoff(random: Random(1));
      final List<int> expected = <int>[5, 10, 20, 40, 60, 60];
      for (int i = 0; i < expected.length; i++) {
        final int secs = backoff.delayFor(i).inSeconds;
        expect(
          secs,
          inInclusiveRange(
            expected[i] - backoffJitterS,
            expected[i] + backoffJitterS,
          ),
        );
      }
    });

    test('never returns a negative delay', () {
      final Backoff backoff = Backoff(random: Random(7));
      for (int i = 0; i < 10; i++) {
        expect(backoff.delayFor(i, 100).inSeconds, greaterThanOrEqualTo(0));
      }
    });
  });

  group('Result', () {
    test('carries values and failures', () {
      const Result<int> ok = Ok<int>(3);
      const Result<int> err = Err<int>(NetworkFailure('down'));
      expect((ok as Ok<int>).value, 3);
      expect((err as Err<int>).failure, isA<NetworkFailure>());
      expect(const ServerFailure('denied', 'auth').code, 'auth');
      expect(const StorageFailure('full'), isA<AppFailure>());
      expect(const LocationFailure('off'), isA<AppFailure>());
    });
  });
}
