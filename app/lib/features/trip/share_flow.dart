// Share-trip entry: consent sheet, permission education, controller
// start, then the trip screen. MapTab buttons call shareTrip and do
// nothing else. Only pilot lines can share. See PLAN.md S06, S07, S08.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pontual/app/providers.dart';
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
/// starts the controller, and navigates to /trip on success. Returns
/// silently when the user declines or the line is not a pilot line.
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
  controller.dispose();
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
}
