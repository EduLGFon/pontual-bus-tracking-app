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
import 'package:pontual/features/trip/trip_supervisor.dart';

/// Why the last [TripController.startTrip] returned false. Null when the
/// last start succeeded or none ran. Read by the share flow to explain
/// the failure instead of failing silently.
enum StartFailure {
  /// OS permission denied; the flow shows the permission sheets.
  permission,

  /// Network or registration failure.
  offline,

  /// No location fix within the wait window.
  noGps,

  /// Server rate, quota, capacity, or maintenance limits.
  busy,

  /// Fix outside the served area.
  outsideArea,

  /// Anything else, including consent mismatches after reposting.
  failed,
}

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

  /// Why the last [startTrip] returned false. Null after a successful
  /// start. The share flow maps this to a user-facing message.
  StartFailure? get failReason => _failReason;
  StartFailure? _failReason;

  LocationService? _locations;
  StreamSubscription<TripFix>? _fixSub;
  PingClient? _ping;
  Timer? _autoEndTimer;
  String? _activeToken;
  TripSupervisor? _supervisor;
  SamplingMode _samplingMode = SamplingMode.waiting;
  bool _checking = false;

  /// True while the web page is hidden (foreground-only sharing).
  /// Fixes are dropped while hidden; the server timeout ends the trip
  /// if the page stays hidden. See PLAN.md 8.12.
  bool get isWebHidden => _webHidden;
  bool _webHidden = false;

  /// Marks the web page hidden or visible. Notifies listeners so the
  /// banner updates. No-op on repeated values.
  void setWebHidden(bool hidden) {
    if (_webHidden == hidden || _disposed) {
      return;
    }
    _webHidden = hidden;
    notifyListeners();
  }

  /// True while the RF16 walking prompt should be on screen.
  bool get walkingPromptVisible => _supervisor?.promptVisible ?? false;

  /// True while sends keep failing and only probes go out.
  bool get isOffline => activeRole(_state) == TripRole.offlineSaver;

  /// True while location services are off (stream paused, banner shown).
  bool get isPaused => _supervisor?.paused ?? false;

  /// Current sampling mode for tests and the location service.
  @visibleForTesting
  SamplingMode get samplingMode => _samplingMode;

  void _set(TripState next) {
    _state = next;
    notifyListeners();
  }

  /// Maps an API failure to the share-flow reason shown to the user.
  StartFailure _classify(AppFailure failure) {
    if (failure is NetworkFailure) {
      return StartFailure.offline;
    }
    if (failure is ServerFailure) {
      switch (failure.code) {
        case 'rate':
        case 'quota':
        case 'capacity':
        case 'maint':
          return StartFailure.busy;
        case 'area':
          return StartFailure.outsideArea;
      }
    }
    return StartFailure.failed;
  }

  /// Starts a trip on [lineId]. Returns false when consent is declined.
  /// [firstFixTimeout] bounds the wait for the first accepted GPS fix;
  /// expiry sets [failReason] to [StartFailure.noGps].
  Future<bool> startTrip({
    required int lineId,
    required String lineLabel,
    required Future<bool> Function() showConsent,
    required Future<void> Function() showPermissions,
    Duration firstFixTimeout = const Duration(seconds: 60),
  }) async {
    _lineId = lineId;
    _lineLabel = lineLabel;
    _endKind = null;
    _endDetail = null;
    _failReason = null;
    _supervisor = TripSupervisor(gateway: _deps.gateway);
    _samplingMode = SamplingMode.waiting;
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
      _failReason = StartFailure.permission;
      _set(tripReduce(_state, TripEvent.permissionsDenied));
      return false;
    }
    _set(tripReduce(_state, TripEvent.permissionsGranted));

    final Result<String> reg = await _deps.api.ensureRegistered();
    if (reg is Err<String>) {
      _failReason = _classify((reg as Err<String>).failure);
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
    TripFix first;
    try {
      first = await stream.first.timeout(firstFixTimeout);
    } on TimeoutException {
      await _stopLocal();
      _failReason = StartFailure.noGps;
      _set(const TripIdle());
      return false;
    }
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
      final AppFailure failure = (started as Err<TripInstruction>).failure;
      _failReason = _classify(failure);
      if (failure is ServerFailure && failure.code == 'consent') {
        // Server never recorded our consent: forget the confirmation so
        // the next tap reposts before retrying the start.
        await _deps.consentStore.clearPosted();
      }
      _set(tripReduce(_state, TripEvent.startFailed));
      _set(const TripIdle());
      return false;
    }
    _startedAtMs = _deps.clock.nowMs();
    _supervisor?.begin(_startedAtMs!);
    _set(tripReduce(_state, TripEvent.startConfirmed));
    _runLoop(token, stream);
    return true;
  }

  void _runLoop(String token, Stream<TripFix> stream) {
    _activeToken = token;
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
      if (_webHidden) {
        return;
      }
      _onFix(fix);
      _ping?.queue(_fixBody(fix), (PingOutcome o) => _onOutcome(token, o));
    });
    _autoEndTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      unawaited(_checkAutoEnd(token));
    });
  }

  void _onFix(TripFix fix) {
    final TripSupervisor? supervisor = _supervisor;
    if (supervisor == null) {
      return;
    }
    final bool hadPrompt = supervisor.promptVisible;
    supervisor.onFix(fix, _deps.clock.nowMs());
    if (supervisor.promptVisible != hadPrompt) {
      notifyListeners();
    }
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
    if (_disposed) {
      return;
    }
    if (outcome.end != null) {
      void end() async {
        await _finish(token, _kindFor(outcome.end!), outcome.end);
      }

      end();
      return;
    }
    final TripSupervisor? supervisor = _supervisor;
    if (supervisor == null) {
      return;
    }
    supervisor.onPingSuccess(_deps.clock.nowMs());
    if (isOffline) {
      _set(tripReduce(_state, TripEvent.wentOnline));
    }
    if (outcome.role == 'L') {
      _set(tripReduce(_state, TripEvent.roleLeader));
    } else if (outcome.role == 'F') {
      _set(tripReduce(_state, TripEvent.roleFollower));
    }
    _applyRound(supervisor);
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

  Future<void> _checkAutoEnd(String token) async {
    final TripSupervisor? supervisor = _supervisor;
    if (_disposed ||
        _checking ||
        _startedAtMs == null ||
        supervisor == null ||
        !tripInProgress(_state)) {
      return;
    }
    _checking = true;
    try {
      await supervisor.pollEnvironment(_deps.clock.nowMs());
      await _applyRound(supervisor, token: token);
    } finally {
      _checking = false;
    }
  }

  /// Applies one supervision round: ends, offline flips, sampling, prompt.
  Future<void> _applyRound(TripSupervisor supervisor, {String? token}) async {
    if (_startedAtMs == null || !tripInProgress(_state)) {
      return;
    }
    final bool hadPrompt = supervisor.promptVisible;
    final Supervision round = supervisor.evaluate(
      role: _serverRole(),
      failures: _ping?.consecutiveFailures ?? 0,
      wasOffline: isOffline,
      startedAtMs: _startedAtMs!,
      nowMs: _deps.clock.nowMs(),
    );
    final AutoEndReason? reason = round.endReason;
    if (reason != null && token != null) {
      final TripEndKind kind =
          reason == AutoEndReason.permissionRevoked ||
              reason == AutoEndReason.gpsOff
          ? TripEndKind.permission
          : TripEndKind.automatic;
      await _finish(token, kind, _detailFor(reason));
      return;
    }
    if (round.offline && !isOffline) {
      _set(tripReduce(_state, TripEvent.wentOffline));
    }
    final LocationService? locations = _locations;
    if (locations != null) {
      _samplingMode = locations.requestMode(round.wanted, _deps.clock.nowMs());
    }
    if (supervisor.promptVisible != hadPrompt) {
      notifyListeners();
    }
  }

  String _detailFor(AutoEndReason reason) {
    switch (reason) {
      case AutoEndReason.permissionRevoked:
        return 'permission';
      case AutoEndReason.gpsOff:
        return 'gps';
      case AutoEndReason.walkingTimeout:
        return 'walking';
      case AutoEndReason.maxDuration:
        return 'max';
    }
  }

  /// Runs one auto-end evaluation with the active trip token.
  /// Test hook: the periodic timer owns this in production.
  @visibleForTesting
  Future<void> checkAutoEndForTest() async {
    final String? token = _activeToken;
    if (token != null) {
      await _checkAutoEnd(token);
    }
  }

  /// Feeds one accepted fix through the slow-speed tracker. Test hook:
  /// production fixes arrive from the location stream.
  @visibleForTesting
  void onFixForTest(TripFix fix) {
    _onFix(fix);
  }

  /// RF16: the user confirms they are still on the bus. Hides the prompt
  /// and restarts the slow-speed clock for another 4 minutes.
  void confirmStillRiding() {
    _supervisor?.confirmStillRiding();
    notifyListeners();
  }

  /// RF16: the user confirms they left the bus. Ends the trip as a user end.
  Future<void> confirmLeftBus() async {
    await endTrip();
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
    _autoEndTimer = null;
    _activeToken = null;
    _webHidden = false;
    _supervisor?.reset();
    _supervisor = null;
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

  /// Whether dispose has run. Late ping outcomes and auto-end checks
  /// after the trip screen is gone are ignored instead of notifying.
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _autoEndTimer?.cancel();
    unawaited(_fixSub?.cancel());
    super.dispose();
  }
}
