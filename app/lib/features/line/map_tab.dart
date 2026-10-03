// S04 Mapa tab: markers, list rows, status row states, recenter, route
// polyline. Vehicles are also listed as text rows so TalkBack users never
// need the map. Leaving the screen stops the stream. See PLAN.md S04.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:pontual/app/providers.dart';
import 'package:pontual/app/strings_pt.dart';
import 'package:pontual/app/theme.dart';
import 'package:pontual/data/realtime/vehicle_repository.dart';
import 'package:pontual/data/static_data/static_data.dart';
import 'package:pontual/features/map/tile_source.dart';
import 'package:pontual/features/trip/share_flow.dart';

/// Map tab for one line.
class MapTab extends ConsumerStatefulWidget {
  /// Creates a map tab.
  const MapTab({
    required this.line,
    required this.tileUrl,
    this.httpClient,
    super.key,
  });

  /// Line being watched.
  final StaticLine line;

  /// Tile URL template from remote config.
  final String tileUrl;

  /// Test-only HTTP client for tiles. Null uses the real network.
  final http.Client? httpClient;

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab> {
  final MapController _map = MapController();
  Timer? _refresh;
  bool _panned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(vehicleRepoProvider(widget.line.id)).start(widget.line.id);
      }
    });
    _refresh = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VehicleRepository repo = ref.watch(
      vehicleRepoProvider(widget.line.id),
    );
    repo.evaluateAge();
    if (!widget.line.pilot) {
      return _note(
        context,
        'Esta linha ainda não tem rastreamento ao vivo. Veja os horários.',
        false,
      );
    }
    final List<ClientVehicle> vehicles = repo.vehicles;
    return Column(
      children: <Widget>[
        Expanded(
          child: Stack(
            children: <Widget>[
              PontualMapWithMarkers(
                line: widget.line,
                vehicles: vehicles,
                tileUrl: widget.tileUrl,
                map: _map,
                onPan: () => setState(() => _panned = true),
                httpClient: widget.httpClient,
              ),
              if (_panned)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Semantics(
                    label: 'Recentralizar',
                    button: true,
                    child: FloatingActionButton.small(
                      onPressed: () {
                        setState(() => _panned = false);
                        if (vehicles.isNotEmpty) {
                          _map.move(
                            LatLng(vehicles.first.lat, vehicles.first.lng),
                            14,
                          );
                        }
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _statusRow(context, repo, vehicles),
        Expanded(
          child: vehicles.isEmpty
              ? _emptyCard(context)
              : ListView.builder(
                  itemCount: vehicles.length,
                  itemBuilder: (BuildContext context, int i) {
                    final ClientVehicle v = vehicles[i];
                    return Semantics(
                      label:
                          'Ônibus ${i + 1}, há ${v.ageS} segundos, ${v.kmh} km por hora',
                      button: true,
                      child: ListTile(
                        title: Text('Ônibus ${i + 1}'),
                        subtitle: Text('há ${v.ageS} s · ${v.kmh} km/h'),
                        onTap: () => _map.move(LatLng(v.lat, v.lng), 15),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () => shareTrip(context, ref, widget.line),
            child: const Text(StringsPt.shareTrip),
          ),
        ),
      ],
    );
  }

  Widget _statusRow(
    BuildContext context,
    VehicleRepository repo,
    List<ClientVehicle> vehicles,
  ) {
    final String text;
    final Color dot;
    switch (repo.status) {
      case StreamStatus.live:
        text = vehicles.isEmpty
            ? 'Ao vivo'
            : 'Ao vivo · atualizado há ${vehicles.first.ageS} s';
        dot = liveColor;
      case StreamStatus.stale:
        text = 'Última posição há ${_ageText(vehicles)}';
        dot = staleColor;
      case StreamStatus.connecting:
        text = 'Conectando…';
        dot = staleColor;
      case StreamStatus.offline:
        text = 'Sem conexão';
        dot = Theme.of(context).colorScheme.error;
    }
    return Semantics(
      label: text,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: <Widget>[
            Icon(Icons.circle, color: dot, size: 12),
            const SizedBox(width: 8),
            Text(text),
          ],
        ),
      ),
    );
  }

  String _ageText(List<ClientVehicle> vehicles) {
    if (vehicles.isEmpty) {
      return 'algum tempo';
    }
    final int ageS = vehicles.first.ageS;
    if (ageS < 60) {
      return '$ageS s';
    }
    return '${ageS ~/ 60} min';
  }

  Widget _emptyCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Nenhum ônibus compartilhando agora. Veja os horários ou '
              'ajude compartilhando sua viagem.',
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                TextButton(
                  onPressed: () =>
                      DefaultTabController.of(context).animateTo(1),
                  child: const Text('Ver horários'),
                ),
                FilledButton(
                  onPressed: () => shareTrip(context, ref, widget.line),
                  child: const Text(StringsPt.shareTrip),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _note(BuildContext context, String text, bool showButton) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(text, style: Theme.of(context).textTheme.bodyLarge),
        if (showButton) ...<Widget>[
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => shareTrip(context, ref, widget.line),
            child: const Text(StringsPt.shareTrip),
          ),
        ],
      ],
    );
  }
}

/// Map with vehicle markers and an optional route polyline.
class PontualMapWithMarkers extends StatelessWidget {
  /// Creates a marker map.
  const PontualMapWithMarkers({
    required this.line,
    required this.vehicles,
    required this.tileUrl,
    required this.map,
    required this.onPan,
    this.route = const <LatLng>[],
    this.httpClient,
    super.key,
  });

  /// Line being watched.
  final StaticLine line;

  /// Current vehicles.
  final List<ClientVehicle> vehicles;

  /// Tile URL template.
  final String tileUrl;

  /// Map controller owned by the parent.
  final MapController map;

  /// Called when the user pans away.
  final void Function() onPan;

  /// Test-only HTTP client for tiles. Null uses the real network.
  final http.Client? httpClient;

  /// Route polyline points, empty until T17 traces land.
  final List<LatLng> route;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FlutterMap(
        mapController: map,
        options: MapOptions(
          initialCenter: vehicles.isEmpty
              ? const LatLng(-18.72, -39.85)
              : LatLng(vehicles.first.lat, vehicles.first.lng),
          initialZoom: 13,
          minZoom: mapMinZoom,
          maxZoom: mapMaxZoom,
          cameraConstraint: CameraConstraint.contain(bounds: mapBounds),
          backgroundColor: Theme.of(context).colorScheme.surface,
          onPositionChanged: (MapCamera camera, bool hasGesture) {
            if (hasGesture) {
              onPan();
            }
          },
        ),
        children: <Widget>[
          osmTileLayer(tileUrl, httpClient: httpClient),
          if (route.isNotEmpty)
            PolylineLayer<Object>(
              polylines: <Polyline<Object>>[Polyline<Object>(points: route)],
            ),
          MarkerLayer(
            markers: <Marker>[
              for (int i = 0; i < vehicles.length; i++)
                Marker(
                  point: LatLng(vehicles[i].lat, vehicles[i].lng),
                  width: 40,
                  height: 40,
                  child: Semantics(
                    label: 'Ônibus ${i + 1}',
                    child: Container(
                      decoration: BoxDecoration(
                        color: badgeColorFor(line.id),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
