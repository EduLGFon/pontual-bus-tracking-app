// Riverpod providers wiring features to data. Side effects live in
// controllers, not widgets. Providers are overridable in tests.
// See PLAN.md 14.3.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:pontual/core/config/env.dart';
import 'package:pontual/core/errors/failures.dart';
import 'package:pontual/core/time/clock.dart';
import 'package:pontual/data/api/bus_api.dart';
import 'package:pontual/data/api/dto.dart';
import 'package:pontual/data/config/remote_config.dart';
import 'package:pontual/data/net/http_client.dart';
import 'package:pontual/data/prefs/token_store.dart';
import 'package:pontual/data/realtime/vehicle_repository.dart';
import 'package:pontual/data/static_data/static_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Shared keep-alive HTTP client for the app lifetime.
final Provider<http.Client> httpClientProvider = Provider<http.Client>((
  Ref ref,
) {
  final http.Client client = createHttpClient();
  ref.onDispose(client.close);
  return client;
});

/// Opaque device token storage.
final Provider<TokenStore> tokenStoreProvider = Provider<TokenStore>((Ref ref) {
  return const TokenStore();
});

/// API client. Performs no network calls until used by trip sharing.
final Provider<BusApi> busApiProvider = Provider<BusApi>((Ref ref) {
  final TokenStore store = ref.watch(tokenStoreProvider);
  return BusApi(
    client: ref.watch(httpClientProvider),
    baseUrl: () => apiBaseUrl,
    readToken: store.read,
    writeToken: store.write,
  );
});

/// Static data repository built from bundled assets.
final FutureProvider<StaticDataRepository> staticDataRepoProvider =
    FutureProvider<StaticDataRepository>((Ref ref) async {
      final String manifest = await rootBundle.loadString(
        'assets/data/manifest.json',
      );
      final String linesName = _linesNameOf(manifest);
      final String lines = await rootBundle.loadString(
        'assets/data/$linesName',
      );
      return StaticDataRepository(
        client: ref.watch(httpClientProvider),
        staticBaseUrl: () => staticBaseUrl,
        bundleManifestJson: manifest,
        bundleLinesJson: lines,
        prefs: SharedPreferences.getInstance,
        nowMs: () => DateTime.now().millisecondsSinceEpoch,
      );
    });

/// Extracts the lines file name from a manifest document.
String _linesNameOf(String manifest) {
  try {
    final Map<String, dynamic> decoded =
        jsonDecode(manifest) as Map<String, dynamic>;
    final String? name = decoded['lines'] as String?;
    if (name != null && name.isNotEmpty) {
      return name;
    }
  } catch (_) {
    // Fall through to the fallback name.
  }
  return 'lines.json';
}

/// Cached lines shown instantly on first paint.
final FutureProvider<List<StaticLine>> linesProvider =
    FutureProvider<List<StaticLine>>((Ref ref) async {
      final StaticDataRepository repo = await ref.watch(
        staticDataRepoProvider.future,
      );
      return repo.lines();
    });

/// Live-lines indicator. Loading or error states show no dots rather than
/// spinners: cached content never waits on the network.
final FutureProvider<LiveLines> liveProvider = FutureProvider<LiveLines>((
  Ref ref,
) async {
  final BusApi api = ref.watch(busApiProvider);
  final result = await api.getLive();
  if (result is Ok<LiveLines>) {
    return result.value;
  }
  return const LiveLines(<List<int>>[]);
});

/// Remote flags repository.
final FutureProvider<RemoteConfigRepository> remoteConfigRepoProvider =
    FutureProvider<RemoteConfigRepository>((Ref ref) async {
      final String bundle = await rootBundle.loadString(
        'assets/data/config.json',
      );
      return RemoteConfigRepository(
        client: ref.watch(httpClientProvider),
        staticBaseUrl: () => staticBaseUrl,
        bundleConfigJson: bundle,
        prefs: SharedPreferences.getInstance,
        nowMs: () => DateTime.now().millisecondsSinceEpoch,
      );
    });

/// Tile URL template from remote flags with an OSM fallback.
final FutureProvider<String> tileUrlProvider = FutureProvider<String>((
  Ref ref,
) async {
  try {
    final RemoteConfigRepository repo = await ref.watch(
      remoteConfigRepoProvider.future,
    );
    return (await repo.current()).tileUrl;
  } catch (_) {
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }
});

/// WebSocket base URL derived from the API base URL.
String wsBaseUrlOf(String api) {
  final Uri uri = Uri.parse(api);
  final String scheme = uri.scheme == 'https' ? 'wss' : 'ws';
  return '$scheme://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
}

/// Vehicle stream per line. Leaving the screen stops the stream.
final vehicleRepoProvider = Provider.family<VehicleRepository, int>((
  Ref ref,
  int lineId,
) {
  final BusApi api = ref.watch(busApiProvider);
  final VehicleRepository repo = VehicleRepository(
    fetchSnapshot: (int id) async {
      final Result<VehiclesSnapshot> res = await api.getVehicles(id);
      if (res is Err<VehiclesSnapshot>) {
        throw StateError('snapshot failed');
      }
      final VehiclesSnapshot snap = (res as Ok<VehiclesSnapshot>).value;
      return snap.vehicles
          .map(
            (List<num?> row) => ClientVehicle(
              id: (row[0] as num).toInt(),
              lat: (row[1] as num).toDouble(),
              lng: (row[2] as num).toDouble(),
              heading: row[3]?.toDouble(),
              kmh: (row[4] as num).toDouble(),
              members: (row[5] as num).toInt(),
              ageS: (row[6] as num).toInt(),
            ),
          )
          .toList();
    },
    openChannel: (Uri url) async => WebSocketChannel.connect(url),
    wsBaseUrl: () => wsBaseUrlOf(apiBaseUrl),
    clock: SystemClock(),
    launch: (Future<void> task) {
      unawaited(task);
    },
  );
  ref.onDispose(() {
    unawaited(repo.stop());
  });
  return repo;
});
