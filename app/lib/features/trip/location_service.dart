// Location service producing filtered fixes. The foreground service with
// a persistent notification starts from the visible activity; swiping the
// app away ends the trip. Fixes are filtered client-side and re-checked
// server-side. See PLAN.md 8.6 and spike S1.
// ignore_for_file: prefer_initializing_formals - injected fakes keep
// stable public names while the fields stay private.
import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pontual/core/geo/geo.dart';
import 'package:pontual/domain/trip/sampling_policy.dart';

/// Accepted area for fixes. Mirrors the server bbox.
const BBox fixArea = BBox(
  latMin: -19.05,
  latMax: -18.40,
  lngMin: -40.25,
  lngMax: -39.55,
);

/// Maximum accepted accuracy in meters.
const double fixAccuracyMaxM = 60;

/// Maximum fix age in milliseconds.
const int fixMaxAgeMs = 20000;

/// One accepted fix ready to send.
class TripFix {
  /// Creates a fix.
  const TripFix({
    required this.seq,
    required this.lat,
    required this.lng,
    required this.speedMps,
    required this.heading,
    required this.accuracyM,
    required this.batteryPct,
    required this.charging,
  });

  /// Sequence number per accepted fix.
  final int seq;

  /// Rounded latitude.
  final double lat;

  /// Rounded longitude.
  final double lng;

  /// Rounded speed.
  final double speedMps;

  /// Heading or null.
  final double? heading;

  /// Accuracy in meters.
  final double accuracyM;

  /// Battery level in 5 percent steps.
  final int batteryPct;

  /// Charging flag.
  final bool charging;
}

/// Raw position reading for the pure filter.
class RawFix {
  /// Creates a raw reading.
  const RawFix({
    required this.lat,
    required this.lng,
    required this.accuracyM,
    required this.isMocked,
    required this.timestampMs,
  });

  /// Latitude in degrees.
  final double lat;

  /// Longitude in degrees.
  final double lng;

  /// Accuracy in meters.
  final double accuracyM;

  /// Mock provider flag.
  final bool isMocked;

  /// Reading time in milliseconds.
  final int timestampMs;
}

/// Drops mocked, stale, inaccurate, or out-of-area fixes.
bool acceptFix(RawFix fix, int nowMs) {
  if (fix.isMocked) {
    return false;
  }
  if (nowMs - fix.timestampMs > fixMaxAgeMs) {
    return false;
  }
  if (fix.accuracyM > fixAccuracyMaxM || fix.accuracyM < 0) {
    return false;
  }
  return fixArea.contains(fix.lat, fix.lng);
}

/// Rounds a coordinate to 5 decimals.
double round5(double v) => (v * 100000).round() / 100000;

/// Rounds battery to 5 percent steps.
int batteryBucket(int pct) => (pct ~/ 5) * 5;

/// Location settings per sampling mode.
LocationSettings settingsFor(SamplingMode mode, String lineLabel) {
  final ForegroundNotificationConfig notification =
      ForegroundNotificationConfig(
        notificationTitle: 'Compartilhando viagem - $lineLabel',
        notificationText: 'Toque para abrir ou encerrar',
      );
  switch (mode) {
    case SamplingMode.waiting:
      return AndroidSettings(
        accuracy: LocationAccuracy.medium,
        intervalDuration: const Duration(seconds: 20),
        foregroundNotificationConfig: notification,
      );
    case SamplingMode.leaderMoving:
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        intervalDuration: const Duration(seconds: 12),
        foregroundNotificationConfig: notification,
      );
    case SamplingMode.leaderStill:
      return AndroidSettings(
        accuracy: LocationAccuracy.medium,
        intervalDuration: const Duration(seconds: 30),
        foregroundNotificationConfig: notification,
      );
    case SamplingMode.follower:
    case SamplingMode.offlineSaver:
      return AndroidSettings(
        accuracy: LocationAccuracy.low,
        intervalDuration: const Duration(seconds: 90),
        foregroundNotificationConfig: notification,
      );
    case SamplingMode.paused:
      return const LocationSettings(accuracy: LocationAccuracy.low);
  }
}

/// Produces filtered fixes for the active trip. Only TripController drives
/// this service. See PLAN.md 14.3.
class LocationService {
  /// Creates a service. Production uses geolocator and battery_plus.
  LocationService({
    required Stream<Position> Function(LocationSettings settings)
    positionStream,
    required Future<int> Function() batteryLevel,
    required Future<bool> Function() charging,
    required int Function() nowMs,
  }) : _positionStream = positionStream,
       _batteryLevel = batteryLevel,
       _charging = charging,
       _nowMs = nowMs;

  /// Production service backed by geolocator and battery_plus.
  factory LocationService.production() {
    final Battery battery = Battery();
    return LocationService(
      positionStream: (LocationSettings s) =>
          Geolocator.getPositionStream(locationSettings: s),
      batteryLevel: () => battery.batteryLevel,
      charging: () async {
        final BatteryState state = await battery.onBatteryStateChanged.first;
        return state == BatteryState.charging;
      },
      nowMs: () => DateTime.now().millisecondsSinceEpoch,
    );
  }

  final Stream<Position> Function(LocationSettings settings) _positionStream;
  final Future<int> Function() _batteryLevel;
  final Future<bool> Function() _charging;
  final int Function() _nowMs;

  StreamSubscription<Position>? _sub;
  int _seq = 0;
  int _lastChangeMs = 0;
  SamplingMode _mode = SamplingMode.waiting;

  /// Starts emitting accepted fixes for [mode]. Recreates the stream when
  /// the policy switches modes, at most once per 30 seconds.
  Stream<TripFix> fixes({
    required SamplingMode mode,
    required String lineLabel,
  }) {
    // ignore: close_sinks - owned by this service, closed in onCancel.
    final StreamController<TripFix> controller = StreamController<TripFix>();
    void listen(SamplingMode m) {
      _sub?.cancel();
      _sub = _positionStream(settingsFor(m, lineLabel)).listen((Position p) {
        void handle() async {
          final RawFix raw = RawFix(
            lat: p.latitude,
            lng: p.longitude,
            accuracyM: p.accuracy,
            isMocked: p.isMocked,
            timestampMs: p.timestamp.millisecondsSinceEpoch,
          );
          if (!acceptFix(raw, _nowMs())) {
            return;
          }
          _seq += 1;
          final int level = await _batteryLevel();
          final bool chg = await _charging();
          if (!controller.isClosed) {
            controller.add(
              TripFix(
                seq: _seq,
                lat: round5(raw.lat),
                lng: round5(raw.lng),
                speedMps: (p.speed * 10).round() / 10,
                heading: p.heading >= 0 ? p.heading : null,
                accuracyM: raw.accuracyM,
                batteryPct: batteryBucket(level.clamp(0, 100)),
                charging: chg,
              ),
            );
          }
        }

        handle();
      });
    }

    listen(mode);
    _mode = mode;
    _lastChangeMs = _nowMs();
    controller.onCancel = () async {
      await _sub?.cancel();
      _sub = null;
    };
    return controller.stream;
  }

  /// Requests a mode switch honoring hysteresis. Returns the active mode.
  SamplingMode requestMode(SamplingMode mode, int nowMs) {
    if (nowMs - _lastChangeMs < streamHysteresisMs) {
      return _mode;
    }
    _mode = mode;
    _lastChangeMs = nowMs;
    return _mode;
  }

  /// Current sequence for tests.
  @visibleForTesting
  int get debugSeq => _seq;
}
