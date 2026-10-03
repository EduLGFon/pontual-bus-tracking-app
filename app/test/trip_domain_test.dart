// T29 tests: every state-machine arrow, illegal events ignored,
// sampling modes with hysteresis, auto-end conditions.
import 'package:flutter_test/flutter_test.dart';
import 'package:pontual/domain/trip/auto_end.dart';
import 'package:pontual/domain/trip/sampling_policy.dart';
import 'package:pontual/domain/trip/trip_state.dart';

void main() {
  test('full happy path to idle', () {
    TripState s = const TripIdle();
    for (final TripEvent e in <TripEvent>[
      TripEvent.tapStart,
      TripEvent.consentAccepted,
      TripEvent.permissionsGranted,
      TripEvent.startConfirmed,
      TripEvent.roleLeader,
      TripEvent.tapEnd,
      TripEvent.endConfirmed,
    ]) {
      s = tripReduce(s, e);
    }
    expect(s, isA<TripIdle>());
    expect(tripInProgress(const TripActive(TripRole.leader)), isTrue);
    expect(tripInProgress(const TripIdle()), isFalse);
    expect(activeRole(const TripActive(TripRole.follower)), TripRole.follower);
    expect(activeRole(const TripIdle()), isNull);
  });

  test('declines and denials return to idle', () {
    expect(
      tripReduce(const TripConsent(), TripEvent.consentDeclined),
      isA<TripIdle>(),
    );
    expect(
      tripReduce(const TripPermissions(), TripEvent.permissionsDenied),
      isA<TripIdle>(),
    );
    expect(
      tripReduce(const TripStarting(), TripEvent.startFailed),
      isA<TripIdle>(),
    );
  });

  test('role switches and offline saver round-trip', () {
    TripState s = const TripActive(TripRole.waiting);
    s = tripReduce(s, TripEvent.roleFollower);
    expect(activeRole(s), TripRole.follower);
    s = tripReduce(s, TripEvent.roleLeader);
    expect(activeRole(s), TripRole.leader);
    s = tripReduce(s, TripEvent.wentOffline);
    expect(activeRole(s), TripRole.offlineSaver);
    s = tripReduce(s, TripEvent.wentOnline);
    expect(activeRole(s), TripRole.waiting);
  });

  test('illegal events are ignored', () {
    expect(tripReduce(const TripIdle(), TripEvent.roleLeader), isA<TripIdle>());
    expect(
      tripReduce(const TripConsent(), TripEvent.tapEnd),
      isA<TripConsent>(),
    );
    expect(
      tripReduce(const TripStarting(), TripEvent.wentOffline),
      isA<TripStarting>(),
    );
    expect(
      tripReduce(const TripActive(TripRole.leader), TripEvent.consentAccepted),
      isA<TripActive>(),
    );
    expect(
      tripReduce(const TripEnding(), TripEvent.tapStart),
      isA<TripEnding>(),
    );
  });

  test('sampling modes follow role and connectivity', () {
    SamplingMode mode({
      required String role,
      double speed = 8,
      bool offline = false,
      int still = 0,
      bool paused = false,
    }) {
      return decideMode(
        current: SamplingMode.waiting,
        input: TripModeInput(
          role: role,
          speedMps: speed,
          offline: offline,
          stillS: still,
          paused: paused,
        ),
        nowMs: 100000,
        lastChangeMs: 0,
      );
    }

    expect(mode(role: 'W'), SamplingMode.waiting);
    expect(mode(role: 'L'), SamplingMode.leaderMoving);
    expect(mode(role: 'L', still: 90), SamplingMode.leaderStill);
    expect(mode(role: 'F'), SamplingMode.follower);
    expect(mode(role: 'L', offline: true), SamplingMode.offlineSaver);
    expect(mode(role: 'L', paused: true), SamplingMode.paused);
  });

  test('hysteresis blocks stream recreation within 30 s', () {
    const TripModeInput input = TripModeInput(
      role: 'F',
      speedMps: 8,
      offline: false,
      stillS: 0,
      paused: false,
    );
    expect(
      decideMode(
        current: SamplingMode.leaderMoving,
        input: input,
        nowMs: 10000,
        lastChangeMs: 0,
      ),
      SamplingMode.leaderMoving,
    );
    expect(
      decideMode(
        current: SamplingMode.leaderMoving,
        input: input,
        nowMs: 31000,
        lastChangeMs: 0,
      ),
      SamplingMode.follower,
    );
  });

  test('auto-end fires in priority order', () {
    AutoEndInput base(int now) => AutoEndInput(
      startedAtMs: now - 1000,
      gpsOffSinceMs: null,
      permissionRevoked: false,
      walkingPromptAtMs: null,
    );
    expect(autoEndReason(base(100000), 100000), isNull);
    expect(
      autoEndReason(
        const AutoEndInput(
          startedAtMs: 0,
          gpsOffSinceMs: null,
          permissionRevoked: true,
          walkingPromptAtMs: null,
        ),
        1000,
      ),
      AutoEndReason.permissionRevoked,
    );
    expect(
      autoEndReason(
        const AutoEndInput(
          startedAtMs: 0,
          gpsOffSinceMs: 0,
          permissionRevoked: false,
          walkingPromptAtMs: null,
        ),
        gpsOffAfterMs + 1,
      ),
      AutoEndReason.gpsOff,
    );
    expect(
      autoEndReason(
        const AutoEndInput(
          startedAtMs: 0,
          gpsOffSinceMs: null,
          permissionRevoked: false,
          walkingPromptAtMs: 0,
        ),
        walkingTimeoutMs + 1,
      ),
      AutoEndReason.walkingTimeout,
    );
    expect(autoEndReason(base(0), tripMaxMs + 1), AutoEndReason.maxDuration);
  });
}
