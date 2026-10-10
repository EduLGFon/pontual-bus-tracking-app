// Share-trip entry: consent sheet, permission education, controller
// start, then the trip screen. MapTab buttons call shareTrip and do
// nothing else. Only pilot lines can share. A phased progress sheet
// covers the silent part (register, GPS, start) so a tap never ends
// with nothing. See PLAN.md S06, S07, S08.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pontual/app/providers.dart';
import 'package:pontual/app/strings_pt.dart';
import 'package:pontual/core/config/env.dart';
import 'package:pontual/core/time/clock.dart';
import 'package:pontual/data/config/remote_config.dart';
import 'package:pontual/data/prefs/consent_store.dart';
import 'package:pontual/data/static_data/static_data.dart';
import 'package:pontual/domain/trip/share_phases.dart';
import 'package:pontual/features/trip/consent_sheet.dart';
import 'package:pontual/features/trip/location_service.dart';
import 'package:pontual/features/trip/permission_sheet.dart';
import 'package:pontual/features/trip/share_progress_sheet.dart';
import 'package:pontual/features/trip/share_progress_tracker.dart';
import 'package:pontual/features/trip/trip_controller.dart';
import 'package:pontual/platform/android/permission_gateway.dart';

/// Starts sharing a trip on [line]. Shows consent and permission UI,
/// then a phased progress sheet for the network and GPS steps, and
/// navigates to /trip on success. Declines stay silent; failures keep
/// the progress sheet open with the reason and a retry action.
/// [gateway] is injectable for tests; production uses geolocator.
Future<void> shareTrip(
  BuildContext context,
  WidgetRef ref,
  StaticLine line, {
  PermissionGateway gateway = const GeolocatorPermissionGateway(),
}) async {
  if (!line.pilot) {
    return;
  }
  try {
    await _shareTrip(context, ref, line, gateway);
  } catch (_) {
    // Any unexpected failure (for example the flags fetch throwing
    // before the progress sheet opens) ends here with an explanation,
    // never silently.
    if (!context.mounted) {
      return;
    }
    _tell(context, StringsPt.shareNoConnection);
  }
}

/// Share body; throws nothing, but the caller guards anyway.
Future<void> _shareTrip(
  BuildContext context,
  WidgetRef ref,
  StaticLine line,
  PermissionGateway gateway,
) async {
  if (!await gateway.servicesOn()) {
    if (!context.mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => const LocationOffSheet(),
    );
    return;
  }
  final RemoteConfigRepository remote = await ref.read(
    remoteConfigRepoProvider.future,
  );
  final int consentVersion = (await remote.current()).consentVersion;
  final TripController controller = TripController(
    TripDeps(
      api: ref.read(busApiProvider),
      gateway: gateway,
      consentStore: const ConsentStore(),
      consentVersion: consentVersion,
      locations: LocationService.production,
      clock: SystemClock(),
    ),
  );
  if (!context.mounted) {
    controller.dispose();
    return;
  }
  final ShareProgressTracker tracker = ShareProgressTracker(
    lineId: line.id,
    consentVersion: consentVersion,
    host: _hostOf(apiBaseUrl),
    nowMs: () => DateTime.now().millisecondsSinceEpoch,
  );
  tracker.report(SharePhase.services, SharePhaseStatus.done);
  tracker.report(SharePhase.config, SharePhaseStatus.done);
  bool sheetOpen = false;
  void openSheet() {
    if (sheetOpen || !context.mounted) {
      return;
    }
    sheetOpen = true;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        enableDrag: false,
        isDismissible: false,
        builder: (BuildContext context) => ShareProgressSheet(
          tracker: tracker,
          lineLabel: line.name,
          onCancel: () {
            tracker.cancel();
            controller.cancelStart();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          onRetry: () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
            unawaited(shareTrip(context, ref, line, gateway: gateway));
          },
          onClose: () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ).then((_) => sheetOpen = false),
    );
  }

  final bool started = await controller.startTrip(
    lineId: line.id,
    lineLabel: line.name,
    showConsent: () async {
      if (!context.mounted) {
        return false;
      }
      return await ConsentSheet.show(context) == ConsentChoice.accepted;
    },
    showPermissions: () async {
      if (!context.mounted) {
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) => const PermissionInfoSheet(),
      );
    },
    onPhase: (SharePhase phase, SharePhaseStatus status, {String? errorCode}) {
      tracker.report(phase, status, errorCode: errorCode);
      if (phase == SharePhase.register) {
        openSheet();
      }
    },
  );
  if (!context.mounted) {
    controller.dispose();
    return;
  }
  if (started) {
    if (sheetOpen) {
      Navigator.of(context).pop();
    }
    context.go('/trip', extra: controller);
    return;
  }
  final StartFailure? reason = controller.failReason;
  // Register, GPS, and start failures already show in the open progress
  // sheet with a retry action; only pre-sheet failures need handling
  // here. Declines stay silent.
  if (sheetOpen) {
    controller.dispose();
    return;
  }
  controller.dispose();
  if (!context.mounted) {
    return;
  }
  if (reason == StartFailure.declined) {
    return;
  }
  if (reason == StartFailure.permission) {
    final LocationPermissionState perm = await gateway.check();
    if (!context.mounted) {
      return;
    }
    if (perm == LocationPermissionState.permanentlyDenied) {
      await showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) => const PermissionBlockedSheet(),
      );
    } else if (perm == LocationPermissionState.denied) {
      await showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) => const PermissionDeniedSheet(),
      );
    }
    return;
  }
  _tell(context, _messageFor(reason));
}

/// Maps a start failure to the message shown to the user.
String _messageFor(StartFailure? reason) {
  switch (reason) {
    case StartFailure.offline:
      return StringsPt.shareNoConnection;
    case StartFailure.noGps:
      return StringsPt.shareNoGps;
    case StartFailure.busy:
      return StringsPt.shareBusy;
    case StartFailure.outsideArea:
      return StringsPt.shareOutsideArea;
    case StartFailure.permission:
    case StartFailure.declined:
    case StartFailure.failed:
    case null:
      return StringsPt.shareStartFailed;
  }
}

/// Host of the API base URL for the technical details. Host only.
String _hostOf(String baseUrl) {
  try {
    return Uri.parse(baseUrl).host;
  } catch (_) {
    return '-';
  }
}

/// Shows a short explanation where the tap happened. No-op without a
/// Scaffold (tests); production call sites always have one.
void _tell(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(SnackBar(content: Text(message)));
}
