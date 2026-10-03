// Sampling policy. Pure decision of location-request mode from role,
// motion, and connectivity, with hysteresis: the stream is never
// recreated more than once per 30 seconds. See PLAN.md 8.6.

/// Location request modes.
enum SamplingMode {
  /// Role W: balanced accuracy about every 20 s.
  waiting,

  /// Role L moving: high accuracy about every 10 to 15 s.
  leaderMoving,

  /// Role L still: balanced about every 30 s.
  leaderStill,

  /// Role F: low power about every 90 s with jitter.
  follower,

  /// Offline: follower-like sampling, probes only.
  offlineSaver,

  /// Stream stopped with a banner.
  paused,
}

/// Minimum interval between stream recreations in milliseconds.
const int streamHysteresisMs = 30000;

/// Decides the sampling mode. Returns [current] unchanged when only the
/// hysteresis window blocks a switch.
SamplingMode decideMode({
  required SamplingMode current,
  required TripModeInput input,
  required int nowMs,
  required int lastChangeMs,
}) {
  final SamplingMode wanted = _wanted(input);
  if (wanted == current) {
    return current;
  }
  if (nowMs - lastChangeMs < streamHysteresisMs) {
    return current;
  }
  return wanted;
}

/// Inputs to the sampling decision.
class TripModeInput {
  /// Creates sampling inputs.
  const TripModeInput({
    required this.role,
    required this.speedMps,
    required this.offline,
    required this.stillS,
    required this.paused,
  });

  /// Server role L, F, or W.
  final String role;

  /// Current speed in meters per second.
  final double speedMps;

  /// True after 3 failed sends or 120 s without success.
  final bool offline;

  /// Seconds without motion.
  final int stillS;

  /// True when permission revoked, location off, or mock detected.
  final bool paused;
}

SamplingMode _wanted(TripModeInput input) {
  if (input.paused) {
    return SamplingMode.paused;
  }
  if (input.offline) {
    return SamplingMode.offlineSaver;
  }
  switch (input.role) {
    case 'L':
      if (input.stillS >= 60) {
        return SamplingMode.leaderStill;
      }
      return SamplingMode.leaderMoving;
    case 'F':
      return SamplingMode.follower;
    default:
      return SamplingMode.waiting;
  }
}
