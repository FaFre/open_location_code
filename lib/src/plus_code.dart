import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:open_location_code/src/data/code_area.dart';
import 'package:open_location_code/src/data/constants.dart';
import 'package:open_location_code/src/helpers.dart';

part 'plus_code.validator.dart';

class PlusCode {
  final String _code;
  final bool _verified;

  bool get isValid => _verified || _isValid();

  /// Decodes an Open Location Code into the location coordinates.
  ///
  /// Returns a [CodeArea] object that includes the coordinates of the bounding
  /// box - the lower left, center and upper right.
  CodeArea decode() {
    if (!isFull()) {
      throw ArgumentError(
        'Passed Open Location Code is not a valid full code: $_code',
      );
    }
    // Strip out separator character (we've already established the code is
    // valid so the maximum is one), padding characters and convert to upper
    // case.
    final cleanCode = _code
        .replaceAll(separator, '')
        .replaceAll(RegExp('$padding+'), '')
        .toUpperCase();

    // Initialise the values for each section. We work them out as integers and
    // convert them to floats at the end.
    var normalLat = -latitudeMax * pairPrecision;
    var normalLng = -longitudeMax * pairPrecision;
    var gridLat = 0;
    var gridLng = 0;
    // How many digits do we have to process?
    var digits = min(cleanCode.length, pairCodeLength);
    // Define the place value for the most significant pair.
    var pv = pairFirstPlaceValue;
    // Decode the paired digits.
    for (var i = 0; i < digits; i += 2) {
      normalLat += codeAlphabet.indexOf(cleanCode[i]) * pv;
      normalLng += codeAlphabet.indexOf(cleanCode[i + 1]) * pv;
      if (i < digits - 2) {
        pv = pv ~/ encodingBase;
      }
    }
    // Convert the place value to a float in degrees.
    var latPrecision = pv / pairPrecision;
    var lngPrecision = pv / pairPrecision;
    // Process any extra precision digits.
    if (cleanCode.length > pairCodeLength) {
      // Initialise the place values for the grid.
      var rowpv = gridLatFirstPlaceValue;
      var colpv = gridLngFirstPlaceValue;
      // How many digits do we have to process?
      digits = min(cleanCode.length, maxDigitCount);
      for (var i = pairCodeLength; i < digits; i++) {
        final digitVal = codeAlphabet.indexOf(cleanCode[i]);
        final row = digitVal ~/ gridColumns;
        final col = digitVal % gridColumns;
        gridLat += row * rowpv;
        gridLng += col * colpv;
        if (i < digits - 1) {
          rowpv = rowpv ~/ gridRows;
          colpv = colpv ~/ gridColumns;
        }
      }
      // Adjust the precisions from the integer values to degrees.
      latPrecision = rowpv / finalLatPrecision;
      lngPrecision = colpv / finalLngPrecision;
    }
    // Merge the values from the normal and extra precision parts of the code.
    final lat = normalLat / pairPrecision + gridLat / finalLatPrecision;
    final lng = normalLng / pairPrecision + gridLng / finalLngPrecision;
    // Return the code area.
    return CodeArea(
      southWest: LatLng(lat, lng),
      northEast: LatLng(lat + latPrecision, lng + lngPrecision),
      codeLength: min(cleanCode.length, maxDigitCount),
    );
  }

  /// Recover the nearest matching code to a specified location.
  ///
  /// Given a short Open Location Code of between four and seven characters,
  /// this recovers the nearest matching full code to the specified location.
  /// The number of characters that will be prepended to the short code, depends
  /// on the length of the short code and whether it starts with the separator.
  /// If it starts with the separator, four characters will be prepended. If it
  /// does not, the characters that will be prepended to the short code, where S
  /// is the supplied short code and R are the computed characters, are as
  /// follows:
  ///
  /// * SSSS    -> RRRR.RRSSSS
  /// * SSSSS   -> RRRR.RRSSSSS
  /// * SSSSSS  -> RRRR.SSSSSS
  /// * SSSSSSS -> RRRR.SSSSSSS
  ///
  /// Note that short codes with an odd number of characters will have their
  /// last character decoded using the grid refinement algorithm.
  ///
  /// Args:
  ///
  /// * [shortCode]: A valid short OLC character sequence.
  /// * [referenceLatitude]: The latitude (in signed decimal degrees) to use to
  /// find the nearest matching full code.
  /// * [referenceLongitude]: The longitude (in signed decimal degrees) to use
  ///  to find the nearest matching full code.
  ///
  /// It returns the nearest full Open Location Code to the reference location
  /// that matches the [_code]. Note that the returned code may not have the
  /// same computed characters as the reference location (provided by
  /// [referenceLatitude] and [referenceLongitude]). This is because it returns
  /// the nearest match, not necessarily the match within the same cell. If the
  /// passed code was not a valid short code, but was a valid full code, it is
  /// returned unchanged.
  PlusCode recoverNearest(
    LatLng reference,
  ) {
    if (!isShort()) {
      if (isFull()) {
        return PlusCode(_code.toUpperCase());
      } else {
        throw ArgumentError('Passed short code is not valid: $_code');
      }
    }

    if (reference.longitude == 180) {
      reference = LatLng(reference.latitude, -180);
    }

    // Clean up the passed code.
    final cleanCode = _code.toUpperCase();
    // Compute the number of digits we need to recover.
    final paddingLength = separatorPosition - cleanCode.indexOf(separator);
    // The resolution (height and width) of the padded area in degrees.
    final resolution = pow(encodingBase, 2 - (paddingLength / 2));
    // Distance from the center to an edge (in degrees).
    final halfResolution = resolution / 2.0;

    // Use the reference location to pad the supplied short code and decode it.
    final referenceCode = PlusCode(
      PlusCode.encode(reference)._code.substring(0, paddingLength) + cleanCode,
    );
    final codeArea = referenceCode.decode();

    var centerLatitude = codeArea.center.latitude;
    var centerLongitude = codeArea.center.longitude;

    // How many degrees latitude is the code from the reference? If it is more
    // than half the resolution, we need to move it north or south but keep it
    // within -90 to 90 degrees.
    if (reference.latitude + halfResolution < centerLatitude &&
        centerLatitude - resolution >= -latitudeMax) {
      // If the proposed code is more than half a cell north of the reference location,
      // it's too far, and the best match will be one cell south.
      centerLatitude -= resolution;
    } else if (reference.latitude - halfResolution > centerLatitude &&
        centerLatitude + resolution <= latitudeMax) {
      // If the proposed code is more than half a cell south of the reference location,
      // it's too far, and the best match will be one cell north.
      centerLatitude += resolution;
    }

    // How many degrees longitude is the code from the reference?
    if (reference.longitude + halfResolution < centerLongitude) {
      centerLongitude -= resolution;
    } else if (reference.longitude - halfResolution > centerLongitude) {
      centerLongitude += resolution;
    }

    return PlusCode.encode(
      LatLng(
        centerLatitude,
        centerLongitude,
      ),
      codeLength: codeArea.codeLength,
    );
  }

  /// Remove characters from the start of an OLC [_code].
  ///
  /// This uses a reference location to determine how many initial characters
  /// can be removed from the OLC code. The number of characters that can be
  /// removed depends on the distance between the code center and the reference
  /// location.
  /// The minimum number of characters that will be removed is four. If more
  /// than four characters can be removed, the additional characters will be
  /// replaced with the padding character. At most eight characters will be
  /// removed.
  /// The reference location must be within 50% of the maximum range. This
  /// ensures that the shortened code will be able to be recovered using
  /// slightly different locations.
  ///
  /// It returns either the original code, if the reference location was not
  /// close enough, or the .
  PlusCode shorten(LatLng location) {
    if (!isFull()) {
      throw ArgumentError('Passed code is not valid and full: $_code');
    }

    if (_code.contains(padding)) {
      throw ArgumentError('Cannot shorten padded codes: $_code');
    }

    final cleanCode = _code.toUpperCase();

    final codeArea = PlusCode(cleanCode).decode();
    if (codeArea.codeLength < minTrimmableCodeLen) {
      throw RangeError('Code length must be at least $minTrimmableCodeLen');
    }

    if (location.longitude == 180) {
      location = LatLng(location.latitude, -180);
    }

    // How close are the latitude and longitude to the code center.
    final range = max(
      (codeArea.center.latitude - location.latitude).abs(),
      (codeArea.center.longitude - location.longitude).abs(),
    );

    for (var i = pairResolutions.length - 2; i >= 1; i--) {
      // Check if we're close enough to shorten. The range must be less than 1/2
      // the resolution to shorten at all, and we want to allow some safety, so
      // use 0.3 instead of 0.5 as a multiplier.
      if (range < (pairResolutions[i] * 0.3)) {
        // Trim it.
        return PlusCode(cleanCode.substring((i + 1) * 2));
      }
    }

    return PlusCode(cleanCode);
  }

  PlusCode(this._code) : _verified = true {
    if (!_isValid()) {
      throw ArgumentError(
        'Passed Open Location Code is not a valid code: $_code',
      );
    }
  }

  /// For bulk processing
  const PlusCode.unverified(this._code) : _verified = false;

  /// Encode a location into an Open Location Code.
  ///
  /// Produces a code of the specified length, or the default length if no
  /// length is provided.
  /// The length determines the accuracy of the code. The default length is
  /// 10 characters, returning a code of approximately 13.5x13.5 meters. Longer
  /// codes represent smaller areas, but lengths > 14 are sub-centimetre and so
  /// 11 or 12 are probably the limit of useful codes.
  ///
  /// Args:
  ///
  /// * [latitude]: A latitude in signed decimal degrees. Will be clipped to the
  /// range -90 to 90.
  /// * [longitude]: A longitude in signed decimal degrees. Will be normalised
  /// to the range -180 to 180.
  /// * [codeLength]: The number of significant digits in the output code, not
  /// including any separator characters.
  factory PlusCode.encode(LatLng location, {int codeLength = pairCodeLength}) {
    if (codeLength < 2 || (codeLength < pairCodeLength && codeLength.isOdd)) {
      throw ArgumentError('Invalid Open Location Code length: $codeLength');
    }
    codeLength = min(maxDigitCount, codeLength);

    // Latitude 90 needs to be adjusted to be just less, so the returned code
    // can also be decoded.
    // Longitude 180 is normalized to -180
    location = LatLng(
      (location.latitude == 90)
          ? location.latitude - computeLatitudePrecision(codeLength)
          : location.latitude,
      (location.longitude == 180) ? -180 : location.longitude,
    );

    var code = '';

    // Compute the code.
    // This approach converts each value to an integer after multiplying it by
    // the final precision. This allows us to use only integer operations, so
    // avoiding any accumulation of floating point representation errors.

    // Multiply values by their precision and convert to positive.
    // Force to integers so the division operations will have integer results.
    // Note: Dart requires rounding before truncating to ensure precision!
    var latVal =
        ((location.latitude + latitudeMax) * finalLatPrecision * 1e6).round() ~/
            1e6;
    var lngVal = ((location.longitude + longitudeMax) * finalLngPrecision * 1e6)
            .round() ~/
        1e6;

    // Compute the grid part of the code if necessary.
    if (codeLength > pairCodeLength) {
      for (var i = 0; i < maxDigitCount - pairCodeLength; i++) {
        final latDigit = latVal % gridRows;
        final lngDigit = lngVal % gridColumns;
        final ndx = latDigit * gridColumns + lngDigit;
        code = codeAlphabet[ndx] + code;
        // Note! Integer division.
        latVal ~/= gridRows;
        lngVal ~/= gridColumns;
      }
    } else {
      latVal ~/= pow(gridRows, gridCodeLength);
      lngVal ~/= pow(gridColumns, gridCodeLength);
    }
    // Compute the pair section of the code.
    for (var i = 0; i < pairCodeLength / 2; i++) {
      code = codeAlphabet[lngVal % encodingBase] + code;
      code = codeAlphabet[latVal % encodingBase] + code;
      latVal ~/= encodingBase;
      lngVal ~/= encodingBase;
    }

    // Add the separator character.
    code = code.substring(0, separatorPosition) +
        separator +
        code.substring(separatorPosition);

    // If we don't need to pad the code, return the requested section.
    if (codeLength >= separatorPosition) {
      return PlusCode(code.substring(0, codeLength + 1));
    }
    // Pad and return the code.
    return PlusCode(
      code.substring(0, codeLength) +
          (padding * (separatorPosition - codeLength)) +
          separator,
    );
  }

  @override
  int get hashCode => _code.hashCode;

  @override
  bool operator ==(Object other) {
    return other is PlusCode && other._code == _code;
  }

  @override
  String toString() => _code;
}
