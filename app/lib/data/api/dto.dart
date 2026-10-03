// Typed DTOs for the Pontual API. Field names match the server contract
// in PLAN.md 6.5. No trip or session ids exist anywhere.
import 'package:pontual/core/errors/failures.dart';

/// Server instruction for a reporter: role plus next interval in seconds.
class TripInstruction {
  /// Creates an instruction.
  const TripInstruction({
    required this.role,
    required this.intervalS,
    this.end,
  });

  /// Leader, follower, or waiting.
  final String role;

  /// Seconds until the next ping.
  final int intervalS;

  /// Present when the trip ended: idle, timeout, or abuse.
  final String? end;
}

/// Public vehicle snapshot for one line.
class VehiclesSnapshot {
  /// Creates a snapshot.
  const VehiclesSnapshot({required this.epochS, required this.vehicles});

  /// Snapshot time as epoch seconds.
  final int epochS;

  /// Rows of [id, lat, lng, heading, kmh, n, ageS].
  final List<List<num?>> vehicles;
}

/// Live-lines payload: pairs of line id and capped vehicle count.
class LiveLines {
  /// Creates a live-lines payload.
  const LiveLines(this.rows);

  /// Rows of [lineId, count].
  final List<List<int>> rows;
}

/// Maps an HTTP error response to a typed failure.
ServerFailure mapError(int status, String? code) {
  return ServerFailure('request failed', code ?? 'unknown');
}
