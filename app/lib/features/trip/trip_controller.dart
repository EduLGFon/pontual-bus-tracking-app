// TripController: the only place that starts or stops the foreground
// service and sends pings. Orchestrates consent, permission,
// registration, start, fixes, ping outcomes, auto-end, and manual end.
// Widgets read state and call methods; they hold no logic.
// See PLAN.md 8.5, 14.3, and S08.
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pontual/core/errors/failures.dart';
import 'package:pontual/core/time/clock.dart';
import 'package:pontual/data/api/bus_api.dart';
import 'package:pontual/data/api/dto.dart';
import 'package:pontual/data/prefs/consent_store.dart';
import 'package:pontual/domain/trip/auto_end.dart';
import 'package:pontual/domain/trip/sampling_policy.dart';
import 'package:pontual/domain/trip/trip_state.dart';
import 'package:pontual/features/trip/consent_flow.dart';
import 'package:pontual/features/trip/location_service.dart';
import 'package:pontual/features/trip/permission_sheet.dart';
import 'package:pontual/features/trip/ping_client.dart';

/// Trip end reasons shown on the S09 end card.
enum TripEndKind {
  /// User tapped Desci.
  user,

  /// Idle, timeout, or max duration.
  automatic,

  /// Permission revoked or GPS off.
  permission,

  /// Server abuse decision.
  abuse,

  /// Maintenance or auth failure.
  server,
}

/// Dependencies of the controller. All injected for tests.
class TripDeps {
  /// Creates controller dependencies.
  const TripDeps({
    required this.api,
    required this.gateway,
    required this.consentStore,
    required this.consentVersion,
    required this.locations,
    required this.clock,
  });

  /// Typed API client.
  final BusApi api;

  /// OS permission gateway.
  final PermissionGateway gateway;

  /// Local consent versioning.
  final ConsentStore consentStore;

  /// Current consent text version.
  final int consentVersion;

  /// Location service factory.
  final LocationService Function() locations;

  /// Clock for durations.
  final Clock clock;
}

/// Controls one trip from consent to end states.
class TripController extends ChangeNotifier {
  /// Creates a controller. Starts in [TripIdle].
  TripController(this._deps) : _state = const TripIdle();

  final TripDeps _deps;

  /// Current machine state.
  TripState get state => _state;
  TripState _state;

  /// Line being shared, if any.
  int? get lineId => _lineId;
  int? _lineId;

  /// Human line label for the notification.
  String get lineLabel => _lineLabel;
  String _lineLabel = '';

  /// How the last trip ended, for the S09 card.
  TripEndKind? get endKind => _endKind;
  TripEndKind? _endKind;

  /// Human end reason for automatic ends.
  String? get endDetail => _endDetail;
  String? _endDetail;

  /// Trip start time in ms for the elapsed ticker.
  int? get startedAtMs => _startedAtMs;
  int? _startedAtMs;

  LocationService? _locations;
  StreamSubscription<TripFix>? _fixSub;
  PingClient? _ping;
  Timer? _autoEndTimer;

  void _set(TripState next) {
    _state = next;
    notifyListeners();
  }

  /// Starts a trip on [lineId]. Returns false when consent is declined.
  Future<bool> startTrip({
    required int lineId,
    required String lineLabel,
    required Future<bool> Function() showConsent,
    required Future<void> Function() showPermissions,
  }) async {
    _lineId = lineId;
    _lineLabel = lineLabel;
    _endKind = null;
    _endDetail = null;
    _set(tripReduce(_state, TripEvent.tapStart));

    final ConsentResult consent = await ensureConsent(
      currentVersion: _deps.consentVersion,
      store: _deps.consentStore,
      showSheet: showConsent,
      postConsents: () async {
        final Result<String> reg = await _deps.api.ensureRegistered();
        if (reg is Err<String>) {
          return const Err<bool>(NetworkFailure('register failed'));
        }
        final Result<bool> posted = await _deps.api.postConsents(
          (reg as Ok<String>).value,
          _deps.consentVersion,
        );
        return posted;
      },
    );
    if (consent == ConsentResult.declined) {
      _set(tripReduce(_state, TripEvent.consentDeclined));
      return false;
    }
    _set(tripReduce(_state, TripEvent.consentAccepted));

    await showPermissions();
    final LocationPermissionState perm = await _deps.gateway.request();
    if (perm != LocationPermissionState.granted) {
      _set(tripReduce(_state, TripEvent.permissionsDenied));
      return false;
    }
    _set(tripReduce(_state, TripEvent.permissionsGranted));

    final Result<String> reg = await _deps.api.ensureRegistered();
    if (reg is Err<String>) {
      _set(const TripIdle());
      return false;
    }
    final String token = (reg as Ok<String>).value;
    // Wait for the first accepted fix so POST /v1/trip carries real
    // coordinates inside the bbox. Single subscription: the run loop
    // reuses the same broadcast stream below.
    _locations = _deps.locations();
    final Stream<TripFix> stream = _locations!.fixes(
      mode: SamplingMode.waiting,
      lineLabel: _lineLabel,
    );
    final TripFix first = await stream.first;
    final Result<TripInstruction> started = await _deps.api.startTrip(
      token,
      lineId: lineId,
      lat: first.lat,
      lng: first.lng,
      accuracyM: first.accuracyM,
      batteryPct: first.batteryPct,
      charging: first.charging,
    );
    if (started is Err<TripInstruction>) {
      await _stopLocal();
      _set(tripReduce(_state, TripEvent.startFailed));
      _set(const TripIdle());
      return false;
    }
    _startedAtMs = _deps.clock.nowMs();
    _set(tripReduce(_state, TripEvent.startConfirmed));
    _runLoop(token, stream);
    return true;
  }

  void _runLoop(String token, Stream<TripFix> stream) {
    _ping = PingClient(
      send: (Map<String, dynamic> fix) async {
        final Result<TripInstruction> res = await _deps.api.pingTrip(
          token,
          seq: fix['seq'] as int,
          lat: fix['lat'] as double,
          lng: fix['lng'] as double,
          speedMps: fix['spd'] as double,
          heading: fix['hdg'] as double?,
          accuracyM: fix['acc'] as double,
          batteryPct: fix['bat'] as int,
          charging: fix['chg'] as bool,
          role: _serverRole(),
        );
        if (res is Err<TripInstruction>) {
          return const PingReply(status: 0);
        }
        final TripInstruction inst = (res as Ok<TripInstruction>).value;
        return PingReply(
          status: 200,
          role: inst.role,
          intervalS: inst.intervalS,
          end: inst.end,
        );
      },
      refreshToken: () async {
        await _deps.api.ensureRegistered();
      },
      random: Random.secure(),
      delay: (Duration d) => Future<void>.delayed(d),
    );
    _fixSub = stream.listen((TripFix fix) {
      _ping?.queue(_fixBody(fix), (PingOutcome o) => _onOutcome(token, o));
    });
    _autoEndTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkAutoEnd(token);
    });
  }

  String _serverRole() {
    final TripRole? role = activeRole(_state);
    switch (role) {
      case TripRole.leader:
        return 'L';
      case TripRole.follower:
        return 'F';
      case TripRole.waiting:
      case TripRole.offlineSaver:
      case null:
        return 'W';
    }
  }

  Map<String, dynamic> _fixBody(TripFix fix) {
    return <String, dynamic>{
      'seq': fix.seq,
      'lat': fix.lat,
      'lng': fix.lng,
      'spd': fix.speedMps,
      'hdg': fix.heading,
      'acc': fix.accuracyM,
      'bat': fix.batteryPct,
      'chg': fix.charging,
    };
  }

  void _onOutcome(String token, PingOutcome outcome) {
    if (outcome.end != null) {
      void end() async {
        await _finish(token, _kindFor(outcome.end!), outcome.end);
      }

      end();
      return;
    }
    if (outcome.role == 'L') {
      _set(tripReduce(_state, TripEvent.roleLeader));
    } else if (outcome.role == 'F') {
      _set(tripReduce(_state, TripEvent.roleFollower));
    }
  }

  TripEndKind _kindFor(String end) {
    switch (end) {
      case 'idle':
      case 'timeout':
        return TripEndKind.automatic;
      case 'abuse':
        return TripEndKind.abuse;
      default:
        return TripEndKind.server;
    }
  }

  void _checkAutoEnd(String token) {
    if (_startedAtMs == null) {
      return;
    }
    final AutoEndReason? reason = autoEndReason(
      AutoEndInput(
        startedAtMs: _startedAtMs!,
        gpsOffSinceMs: null,
        permissionRevoked: false,
        walkingPromptAtMs: null,
      ),
      _deps.clock.nowMs(),
    );
    if (reason == AutoEndReason.maxDuration) {
      void end() async {
        await _finish(token, TripEndKind.automatic, 'max');
      }

      end();
    }
  }

  /// Ends the trip now: stops the service, then best-effort server end.
  Future<void> endTrip() async {
    final String? token = await _token();
    _set(tripReduce(_state, TripEvent.tapEnd));
    await _stopLocal();
    if (token != null) {
      try {
        await _deps.api.endTrip(token).timeout(const Duration(seconds: 5));
      } catch (_) {
        // Best effort only.
      }
    }
    _endKind = TripEndKind.user;
    _set(tripReduce(_state, TripEvent.endConfirmed));
  }

  Future<void> _finish(String token, TripEndKind kind, String? detail) async {
    await _stopLocal();
    try {
      await _deps.api.endTrip(token).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Best effort only.
    }
    _endKind = kind;
    _endDetail = detail;
    if (_state is TripActive) {
      _set(tripReduce(_state, TripEvent.tapEnd));
    }
    _set(const TripIdle());
  }

  Future<void> _stopLocal() async {
    _autoEndTimer?.cancel();
    final StreamSubscription<TripFix>? sub = _fixSub;
    _fixSub = null;
    if (sub != null) {
      unawaited(sub.cancel());
    }
    _locations?.stop();
    _locations = null;
    _ping = null;
  }

  Future<String?> _token() async {
    try {
      final Result<String> reg = await _deps.api.ensureRegistered();
      if (reg is Ok<String>) {
        return reg.value;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _autoEndTimer?.cancel();
    unawaited(_fixSub?.cancel());
    super.dispose();
  }
}
