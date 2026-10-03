// Web wake lock wrapper. Holds the Screen Wake Lock during a web trip
// so the screen stays on while sharing in the foreground. Failures are
// silent: the banner tells the user to keep the screen on. See PLAN 8.12.
import 'package:wakelock_plus/wakelock_plus.dart';

/// Controls the web Screen Wake Lock. Injectable for tests.
abstract class WebWakeLock {
  /// Requests the wake lock.
  Future<void> enable();

  /// Releases the wake lock.
  Future<void> disable();

  /// True while the lock is held.
  Future<bool> get enabled;
}

/// Production wake lock backed by wakelock_plus.
class ProdWebWakeLock implements WebWakeLock {
  /// Creates the production wake lock.
  const ProdWebWakeLock();

  @override
  Future<void> enable() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {
      // Unsupported browsers stay usable; the banner carries the message.
    }
  }

  @override
  Future<void> disable() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {
      // Best effort only.
    }
  }

  @override
  Future<bool> get enabled async {
    try {
      return await WakelockPlus.enabled;
    } catch (_) {
      return false;
    }
  }
}

/// Fake wake lock for tests.
class FakeWebWakeLock implements WebWakeLock {
  /// Whether enable was called without a matching disable.
  bool held = false;

  /// Number of enable calls.
  int enables = 0;

  /// Number of disable calls.
  int disables = 0;

  @override
  Future<void> enable() async {
    enables += 1;
    held = true;
  }

  @override
  Future<void> disable() async {
    disables += 1;
    held = false;
  }

  @override
  Future<bool> get enabled async => held;
}
