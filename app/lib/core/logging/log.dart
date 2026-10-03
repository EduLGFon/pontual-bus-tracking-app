// Log wrapper. Debug builds are verbose; release builds keep warnings and
// errors in an in-memory ring buffer that is never sent anywhere and never
// persisted. There is deliberately no overload that accepts coordinates,
// tokens, session ids, or user ids. See PLAN.md 14.9.
// PRIVACY: never log coordinates.
import 'package:flutter/foundation.dart';

/// Log severity levels.
enum LogLevel {
  /// Verbose tracing for debug builds.
  debug,

  /// Noteworthy events for debug builds.
  info,

  /// Kept in the ring buffer.
  warning,

  /// Kept in the ring buffer.
  error,
}

/// Bounded in-memory record of one log line.
class LogRecord {
  /// Creates a log record.
  const LogRecord(this.level, this.message, this.context);

  /// Severity of the record.
  final LogLevel level;

  /// Short static message with no personal data.
  final String message;

  /// Optional safe context (route names, status codes, durations only).
  final String context;
}

/// Application logger with a redaction-by-construction API.
class Log {
  Log._();

  static const int _ringCap = 200;
  static final List<LogRecord> _ring = <LogRecord>[];

  /// Recent warnings and errors, newest last. For on-device debugging only.
  static List<LogRecord> get recent => List<LogRecord>.unmodifiable(_ring);

  /// Clears the ring buffer. Used by tests.
  @visibleForTesting
  static void clearForTest() => _ring.clear();

  /// Logs a debug line (debug builds only).
  static void d(String message, [String context = '']) {
    if (kDebugMode) {
      debugPrint('D $message $context');
    }
  }

  /// Logs an informational line (debug builds only).
  static void i(String message, [String context = '']) {
    if (kDebugMode) {
      debugPrint('I $message $context');
    }
  }

  /// Logs a warning, kept in the ring buffer.
  static void w(String message, [String context = '']) {
    _push(LogRecord(LogLevel.warning, message, context));
    if (kDebugMode) {
      debugPrint('W $message $context');
    }
  }

  /// Logs an error, kept in the ring buffer.
  static void e(String message, [String context = '']) {
    _push(LogRecord(LogLevel.error, message, context));
    if (kDebugMode) {
      debugPrint('E $message $context');
    }
  }

  static void _push(LogRecord record) {
    _ring.add(record);
    while (_ring.length > _ringCap) {
      _ring.removeAt(0);
    }
  }
}
