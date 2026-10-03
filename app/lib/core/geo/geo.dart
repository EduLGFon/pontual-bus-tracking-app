// Pure geographic helpers. Units carry suffixes. Mirrors the server engine
// (server/src/domain/geo.ts) and the data route tool; kept in sync by
// round-trip tests.
import 'dart:math' as math;

/// Mean earth radius in meters.
const double earthRadiusM = 6371000;

/// Degrees latitude per meter of meridian arc.
const double degPerMeterLat = 1 / 111320;

/// Haversine distance in meters between two points.
double distM(double lat1, double lng1, double lat2, double lng2) {
  const double rad = math.pi / 180;
  final double dLat = (lat2 - lat1) * rad;
  final double dLng = (lng2 - lng1) * rad;
  final double a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * rad) *
          math.cos(lat2 * rad) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * earthRadiusM * math.asin(math.sqrt(a));
}

/// Bounding box in degrees.
class BBox {
  /// Creates a bounding box.
  const BBox({
    required this.latMin,
    required this.latMax,
    required this.lngMin,
    required this.lngMax,
  });

  /// Minimum latitude.
  final double latMin;

  /// Maximum latitude.
  final double latMax;

  /// Minimum longitude.
  final double lngMin;

  /// Maximum longitude.
  final double lngMax;

  /// True when the point is inside the box.
  bool contains(double lat, double lng) {
    return lat >= latMin && lat <= latMax && lng >= lngMin && lng <= lngMax;
  }
}

/// Decodes a Google encoded polyline at [precision] decimals.
List<LatLng> decodePolyline(String text, [int precision = 5]) {
  final double factor = math.pow(10, precision).toDouble();
  final List<LatLng> points = <LatLng>[];
  int lat = 0;
  int lng = 0;
  int i = 0;
  while (i < text.length) {
    int shift = 0;
    int delta = 0;
    int b;
    do {
      b = text.codeUnitAt(i++) - 63;
      delta |= (b & 31) << shift;
      shift += 5;
    } while (b >= 32);
    lat += (delta & 1) != 0 ? ~(delta >> 1) : delta >> 1;
    shift = 0;
    delta = 0;
    do {
      b = text.codeUnitAt(i++) - 63;
      delta |= (b & 31) << shift;
      shift += 5;
    } while (b >= 32);
    lng += (delta & 1) != 0 ? ~(delta >> 1) : delta >> 1;
    points.add(LatLng(lat / factor, lng / factor));
  }
  return points;
}

/// Immutable latitude/longitude pair in degrees.
class LatLng {
  /// Creates a coordinate pair.
  const LatLng(this.lat, this.lng);

  /// Latitude in degrees.
  final double lat;

  /// Longitude in degrees.
  final double lng;
}
