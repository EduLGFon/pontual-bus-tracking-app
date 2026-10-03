// T26 tests: tile source compliance and the map widget surface.
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:pontual/features/map/map_widget.dart';
import 'package:pontual/features/map/tile_source.dart';

void main() {
  test('tile source uses the app identifier and capped cache', () {
    expect(tileUserAgent, 'com.spotnik.pontual');
    expect(tileCacheMaxBytes, 50 * 1000 * 1000);
    final TileLayer layer = osmTileLayer(
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      caching: const DisabledMapCachingProvider(),
    );
    expect(layer.urlTemplate, contains('tile.openstreetmap.org'));
    expect(layer.minZoom, mapMinZoom);
    expect(layer.maxZoom, mapMaxZoom);
  });

  testWidgets('map shows tappable OSM attribution', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PontualMap(
            center: LatLng(-18.72, -39.85),
            tileUrlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(RichAttributionWidget), findsOneWidget);
    expect(find.textContaining('OpenStreetMap'), findsWidgets);
  });
}
