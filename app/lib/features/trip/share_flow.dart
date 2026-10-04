// Share-trip entry: consent sheet, permission education, controller
// start, then the trip screen. MapTab buttons call shareTrip and do
// nothing else. Only pilot lines can share. See PLAN.md S06, S07, S08.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pontual/app/providers.dart';
import 'package:pontual/app/strings_pt.dart';
import 'package:pontual/core/time/clock.dart';
import 'package:pontual/data/config/remote_config.dart';
import 'package:pontual/data/prefs/consent_store.dart';
import 'package:pontual/data/static_data/static_data.dart';
import 'package:pontual/features/trip/consent_sheet.dart';
import 'package:pontual/features/trip/location_service.dart';
import 'package:pontual/features/trip/permission_sheet.dart';
import 'package:pontual/features/trip/trip_controller.dart';
import 'package:pontual/platform/android/permission_gateway.dart';

/// Starts sharing a trip on [line]. Shows consent and permission UI,
/// starts the controller, and navigates to /trip on success. Declines
/// and non-pilot lines stay put; every other failure shows a short
/// message where the tap happened, never nothing.
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
    // Any unexpected failure (for example the flags fetch throwing)
    // ends here with an explanation, never silently.
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
  );
  if (!context.mounted) {
    controller.dispose();
    return;
  }
  if (started) {
    context.go('/trip', extra: controller);
    return;
  }
  final StartFailure? reason = controller.failReason;
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

/// Shows a short explanation where the tap happened. No-op without a
/// Scaffold (tests); production call sites always have one.
void _tell(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(SnackBar(content: Text(message)));
}
