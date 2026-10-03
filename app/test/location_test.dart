// T31 tests: fix filters, rounding, mode settings, permission mapping.
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pontual/domain/trip/sampling_policy.dart';
import 'package:pontual/features/trip/location_service.dart';
import 'package:pontual/platform/android/permission_gateway.dart';

void main() {
  test('filter drops mocked, stale, bad, and far fixes', () {
    const RawFix good = RawFix(
      lat: -18.72,
      lng: -39.85,
      accuracyM: 10,
      isMocked: false,
      timestampMs: 100000,
    );
    expect(acceptFix(good, 100000), isTrue);
    expect(
      acceptFix(
        const RawFix(
          lat: -18.72,
          lng: -39.85,
          accuracyM: 10,
          isMocked: true,
          timestampMs: 100000,
        ),
        100000,
      ),
      isFalse,
    );
    expect(acceptFix(good, 100000 + 20001), isFalse);
    expect(
      acceptFix(
        const RawFix(
          lat: -18.72,
          lng: -39.85,
          accuracyM: 500,
          isMocked: false,
          timestampMs: 100000,
        ),
        100000,
      ),
      isFalse,
    );
    expect(
      acceptFix(
        const RawFix(
          lat: -18.0,
          lng: -39.85,
          accuracyM: 10,
          isMocked: false,
          timestampMs: 100000,
        ),
        100000,
      ),
      isFalse,
    );
  });

  test('rounding follows the send format', () {
    expect(round5(-18.723456), closeTo(-18.72346, 1e-9));
    expect(batteryBucket(83), 80);
    expect(batteryBucket(100), 100);
  });

  test('settings carry the foreground notification', () {
    final LocationSettings waiting = settingsFor(SamplingMode.waiting, '60');
    expect(waiting, isA<AndroidSettings>());
    final AndroidSettings active =
        settingsFor(SamplingMode.leaderMoving, '60') as AndroidSettings;
    expect(active.intervalDuration, const Duration(seconds: 12));
    expect(
      active.foregroundNotificationConfig?.notificationTitle,
      contains('60'),
    );
    final AndroidSettings follower =
        settingsFor(SamplingMode.follower, '60') as AndroidSettings;
    expect(follower.intervalDuration, const Duration(seconds: 90));
  });

  test('gateway constructs without platform calls', () {
    expect(const GeolocatorPermissionGateway(), isNotNull);
  });
}
