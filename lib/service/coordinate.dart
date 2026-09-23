import 'package:latlong2/latlong.dart';
import 'package:proj4dart/proj4dart.dart';

class TaiwanGeoConverter {
  static final Projection _wgs84 = Projection.get('EPSG:4326')!;

  static final Projection _twd97 = Projection.parse(
    '+proj=tmerc +lat_0=0 +lon_0=121 +k=0.9999 +x_0=250000 +y_0=0 '
        '+ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs',
  );

  /// Transforms WGS84 (latitude, longitude) to TWD97 (X, Y) in meters
  static Point wgs84ToTwd97({required LatLng point}) {
    // proj4dart Point order: x = longitude, y = latitude
    final pointWgs84 = Point(x: point.longitude, y: point.latitude);
    return _wgs84.transform(_twd97, pointWgs84);
  }
}