import 'dart:math';

import 'package:open_location_code/src/data/constants.dart';

/// Compute the latitude precision value for a given code length.
///
/// Lengths <= 10 have the same precision for latitude and longitude, but
/// lengths > 10 have different precisions due to the grid method having fewer
/// columns than rows.
num computeLatitudePrecision(int codeLength) {
  if (codeLength <= 10) {
    return pow(encodingBase, (codeLength ~/ -2) + 2);
  }
  return 1 / (pow(encodingBase, 3) * pow(gridRows, codeLength - 10));
}
