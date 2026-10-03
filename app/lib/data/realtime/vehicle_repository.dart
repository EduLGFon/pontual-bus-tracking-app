// Vehicle repository: snapshot first, then the read-only WebSocket
// stream, with a watchdog resync and a polling fallback. Stops cleanly
// when the UI goes to background. Unknown server keys are ignored so the
// app-level heartbeat never breaks parsing. See PLAN.md 6.8 and 15.3.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pontual/core/time/clock.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// One vehicle as shown on the map and in the list.
class ClientVehicle {
  /// Creates a client vehicle.
  const ClientVehicle({
    required this.id,
    required this.lat,
    required this.lng,
    required this.heading,
    required this.kmh,
    required this.members,
    required this.ageS,
  });

  /// Vehicle id from the snapshot row.
  final int id;

  /// Latitude in degrees.
  final double lat;

  /// Longitude in degrees.
  final double lng;

  /// Heading in degrees, if reported.
  final double? heading;

  /// Speed in km/h.
  final double kmh;

  /// Member count capped at 3.
  final int members;

  /// Snapshot age in seconds.
  final int ageS;

  /// Parses a snapshot row [id, lat, lng, hdg, kmh, n, age].
  factory ClientVehicle.fromRow(List<dynamic> row) {
    return ClientVehicle(
      id: row[0] as int,
      lat: (row[1] as num).toDouble(),
      lng: (row[2] as num).toDouble(),
      heading: (row[3] as num?)?.toDouble(),
      kmh: (row[4] as num).toDouble(),
      members: row[5] as int,
      ageS: row[6] as int,
    );
  }
}

/// Stream status shown in the status row.
enum StreamStatus {
  /// Connecting to the stream.
  connecting,

  /// Fresh snapshot within the stale threshold.
  live,

  /// Snapshot older than the stale threshold.
  stale,

  /// No connection and no usable cache.
  offline,
}

/// Maximum snapshot age before the status row turns stale, in seconds.
const int staleAfterS = 45;

/// Watchdog resync delay without stream messages, in seconds.
const int watchdogResyncS = 45;

/// Socket-down delay before the polling fallback starts, in seconds.
const int pollFallbackAfterS = 30;

/// Polling interval while the socket is down, in seconds.
const int pollIntervalS = 15;

/// Opens a WebSocket channel. Injectable for tests.
typedef ChannelFactory = Future<WebSocketChannel> Function(Uri url);

/// Fetches one snapshot over HTTP. Injectable for tests.
typedef SnapshotFetcher = Future<List<ClientVehicle>> Function(int lineId);

/// Vehicle stream for one line with snapshot, socket, watchdog, polling.
// ignore_for_file: prefer_initializing_formals - injected dependencies keep
// stable public names while the fields stay private.
class VehicleRepository {
  /// Creates a repository. Starts nothing until [start].
  VehicleRepository({
    required SnapshotFetcher fetchSnapshot,
    required ChannelFactory openChannel,
    required String Function() wsBaseUrl,
    required Clock clock,
    required void Function(Future<void> task) launch,
  }) : _fetchSnapshot = fetchSnapshot,
       _openChannel = openChannel,
       _wsBaseUrl = wsBaseUrl,
       _clock = clock,
       _launch = launch;

  final SnapshotFetcher _fetchSnapshot;
  final ChannelFactory _openChannel;
  final String Function() _wsBaseUrl;
  final Clock _clock;
  final void Function(Future<void> task) _launch;

  /// Currently watched line, if started.
  int? get lineId => _lineId;
  int? _lineId;

  /// Latest vehicles.
  List<ClientVehicle> get vehicles =>
      List<ClientVehicle>.unmodifiable(_vehicles);
  List<ClientVehicle> _vehicles = <ClientVehicle>[];

  /// Current stream status.
  StreamStatus get status => _status;
  StreamStatus _status = StreamStatus.connecting;

  /// Monotonic time of the last accepted snapshot in ms, if any.
  int? get lastSnapshotAtMs => _lastSnapshotAtMs;
  int? _lastSnapshotAtMs;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _watchdog;
  Timer? _poller;
  int? _socketDownAtMs;
  bool _stopped = true;

  /// Starts watching [lineId]: snapshot first, then the stream.
  Future<void> start(int lineId) async {
    await stop();
    _stopped = false;
    _lineId = lineId;
    _status = StreamStatus.connecting;
    await _resync();
    if (_stopped) {
      return;
    }
    await _connect();
    _armWatchdog();
  }

  /// Stops everything: socket, watchdog, polling. Safe to call twice.
  Future<void> stop() async {
    _stopped = true;
    _watchdog?.cancel();
    _watchdog = null;
    _poller?.cancel();
    _poller = null;
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {
      // Ignore close failures on teardown.
    }
    _channel = null;
    _lineId = null;
  }

  /// Ages the status against the fake-friendly monotonic clock.
  void evaluateAge() {
    if (_lastSnapshotAtMs == null) {
      _status = _channel == null
          ? StreamStatus.offline
          : StreamStatus.connecting;
      return;
    }
    final int ageS = (_clock.monotonicMs() - _lastSnapshotAtMs!) ~/ 1000;
    _status = ageS > staleAfterS ? StreamStatus.stale : StreamStatus.live;
  }

  Future<void> _resync() async {
    final int? line = _lineId;
    if (line == null || _stopped) {
      return;
    }
    try {
      _vehicles = await _fetchSnapshot(line);
      _lastSnapshotAtMs = _clock.monotonicMs();
      evaluateAge();
    } catch (_) {
      _status = StreamStatus.offline;
    }
  }

  Future<void> _connect() async {
    final int? line = _lineId;
    if (line == null || _stopped) {
      return;
    }
    try {
      final WebSocketChannel channel = await _openChannel(
        Uri.parse('${_wsBaseUrl()}/v1/stream'),
      );
      if (_stopped || _lineId != line) {
        unawaited(channel.sink.close());
        return;
      }
      _channel = channel;
      _socketDownAtMs = null;
      _poller?.cancel();
      _poller = null;
      channel.sink.add(
        jsonEncode(<String, dynamic>{'op': 'sub', 'line': line}),
      );
      _sub = channel.stream.listen(
        (dynamic msg) => _onMessage(msg),
        onDone: () => _onSocketDown(),
        onError: (_) => _onSocketDown(),
        cancelOnError: false,
      );
    } catch (_) {
      _onSocketDown();
    }
  }

  void _onMessage(dynamic msg) {
    if (_stopped) {
      return;
    }
    try {
      final Map<String, dynamic> decoded =
          jsonDecode(msg as String) as Map<String, dynamic>;
      final List<dynamic>? rows = decoded['v'] as List<dynamic>?;
      if (rows == null) {
        return;
      }
      _vehicles = rows
          .map(
            (dynamic r) => ClientVehicle.fromRow((r as List<dynamic>).toList()),
          )
          .toList();
      _lastSnapshotAtMs = _clock.monotonicMs();
      evaluateAge();
    } catch (_) {
      // Ignore malformed frames; the watchdog resyncs.
    }
  }

  void _onSocketDown() {
    _channel = null;
    _socketDownAtMs ??= _clock.monotonicMs();
    _armPoller();
  }

  void _armWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_stopped) {
        _watchdogBody();
      }
    });
  }

  /// One watchdog pass: resync when quiet, arm polling when long down.
  void _watchdogBody() {
    evaluateAge();
    final int? last = _lastSnapshotAtMs;
    final int now = _clock.monotonicMs();
    if (last == null || now - last > watchdogResyncS * 1000) {
      // Fire and forget by design: the next tick retries on failure.
      _launch(_resync());
    }
    if (_channel == null &&
        _socketDownAtMs != null &&
        now - _socketDownAtMs! > pollFallbackAfterS * 1000 &&
        _poller == null) {
      _armPoller();
    }
  }

  void _armPoller() {
    if (_stopped || _poller != null) {
      return;
    }
    _poller = Timer.periodic(const Duration(seconds: pollIntervalS), (_) {
      if (!_stopped) {
        _resync();
      }
    });
  }

  /// Exposed for tests: forces the watchdog path without timers.
  @visibleForTesting
  void debugSocketDown() => _onSocketDown();

  /// Exposed for tests: runs one watchdog pass without waiting.
  @visibleForTesting
  void debugWatchdogTick() => _watchdogBody();

  /// Exposed for tests: true while the polling fallback is armed.
  @visibleForTesting
  bool get debugPolling => _poller != null;
}
