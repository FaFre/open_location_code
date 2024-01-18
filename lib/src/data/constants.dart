import 'dart:math';

/// A separator used to break the code into two parts to aid memorability.
const separator = '+'; // 43 Ascii

/// The number of characters to place before the separator.
const separatorPosition = 8;

/// The character used to pad codes.
const padding = '0'; // 48 in Ascii

/// The character set used to encode the values.
const codeAlphabet = '23456789CFGHJMPQRVWX';

/// The base to use to convert numbers to/from.
const encodingBase = codeAlphabet.length;

/// The maximum value for latitude in degrees.
const latitudeMax = 90;

/// The maximum value for longitude in degrees.
const longitudeMax = 180;

// The max number of digits to process in a plus code.
const maxDigitCount = 15;

/// Maximum code length using lat/lng pair encoding. The area of such a
/// code is approximately 13x13 meters (at the equator), and should be suitable
/// for identifying buildings. This excludes prefix and separator characters.
const pairCodeLength = 10;

/// First place value of the pairs (if the last pair value is 1).
final pairFirstPlaceValue = pow(encodingBase, pairCodeLength / 2 - 1).toInt();

/// Inverse of the precision of the pair section of the code.
final pairPrecision = pow(encodingBase, 3).toInt();

/// The resolution values in degrees for each position in the lat/lng pair
/// encoding. These give the place value of each position, and therefore the
/// dimensions of the resulting area.
const pairResolutions = <double>[20.0, 1.0, .05, .0025, .000125];

/// Number of digits in the grid precision part of the code.
const gridCodeLength = maxDigitCount - pairCodeLength;

/// Number of columns in the grid refinement method.
const gridColumns = 4;

/// Number of rows in the grid refinement method.
const gridRows = 5;

/// First place value of the latitude grid (if the last place is 1).
final gridLatFirstPlaceValue = pow(gridRows, gridCodeLength - 1).toInt();

/// First place value of the longitude grid (if the last place is 1).
final gridLngFirstPlaceValue = pow(gridColumns, gridCodeLength - 1).toInt();

/// Multiply latitude by this much to make it a multiple of the finest
/// precision.
final finalLatPrecision = pairPrecision * pow(gridRows, gridCodeLength).toInt();

/// Multiply longitude by this much to make it a multiple of the finest
/// precision.
final finalLngPrecision =
    pairPrecision * pow(gridColumns, gridCodeLength).toInt();

/// Minimum length of a code that can be shortened.
const minTrimmableCodeLen = 6;

/// Decoder lookup table.
/// Position is ASCII character value, value is:
/// * -2: illegal.
/// * -1: Padding or Separator
/// * >= 0: index in the alphabet.
const decodeTable = <int>[
  -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, //
  -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, //
  -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -2, -2, -2, -2, //
  -1, -2, 0, 1, 2, 3, 4, 5, 6, 7, -2, -2, -2, -2, -2, -2, //
  -2, -2, -2, 8, -2, -2, 9, 10, 11, -2, 12, -2, -2, 13, -2, -2, //
  14, 15, 16, -2, -2, -2, 17, 18, 19, -2, -2, -2, -2, -2, -2, -2, //
  -2, -2, -2, 8, -2, -2, 9, 10, 11, -2, 12, -2, -2, 13, -2, -2, //
  14, 15, 16, -2, -2, -2, 17, 18, 19, -2, -2, -2, -2, -2, -2, -2,
];
