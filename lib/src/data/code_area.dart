import 'package:latlong2/latlong.dart';

/// Coordinates of a decoded Open Location Code.
///
/// The coordinates include the latitude and longitude of the lower left and
/// upper right corners and the center of the bounding box for the area the
/// code represents.
class CodeArea {
  final LatLng southWest;
  final LatLng northEast;

  LatLng get center => LatLng(
        (southWest.latitude + northEast.latitude) / 2,
        (southWest.longitude + northEast.longitude) / 2,
      );

  final int codeLength;

  /// Create a [CodeArea].
  ///
  /// Args:
  ///
  /// *[south]: The south in degrees.
  /// *[west]: The west in degrees.
  /// *[north]: The north in degrees.
  /// *[east]: The east in degrees.
  /// *[code_length]: The number of significant characters that were in the code.
  /// This excludes the separator.
  const CodeArea({
    required this.southWest,
    required this.northEast,
    required this.codeLength,
  });

  @override
  String toString() =>
      'CodeArea(south:${southWest.latitude}, west:${southWest.longitude}, north:${northEast.latitude}, east:${northEast.longitude}, codelen: $codeLength)';
}
