// Reusable map widget: OSM tiles, capped cache, bounds, attribution.
// Markers arrive in T28; the map renders its area and attribution here.
// See PLAN.md 8.9 and S3 results.
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:pontual/features/map/tile_source.dart';
import 'package:url_launcher/url_launcher.dart';

/// OSM copyright URL opened from the attribution.
const String osmCopyrightUrl = 'https://www.openstreetmap.org/copyright';

/// Live map with tile layer, bounds, and tappable OSM attribution.
class PontualMap extends StatelessWidget {
  /// Creates a map centered on [center] with [tileUrlTemplate].
  const PontualMap({
    required this.center,
    required this.tileUrlTemplate,
    this.httpClient,
    super.key,
  });

  /// Initial center.
  final LatLng center;

  /// Tile URL template from remote config.
  final String tileUrlTemplate;

  /// Test-only HTTP client for tiles. Null uses the real network.
  final http.Client? httpClient;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 13,
          minZoom: mapMinZoom,
          maxZoom: mapMaxZoom,
          cameraConstraint: CameraConstraint.contain(bounds: mapBounds),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        children: <Widget>[
          osmTileLayer(tileUrlTemplate, httpClient: httpClient),
          RichAttributionWidget(
            attributions: <SourceAttribution>[
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: () => launchUrl(Uri.parse(osmCopyrightUrl)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
