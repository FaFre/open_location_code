part of 'plus_code.dart';

extension PlusCodeValidator on PlusCode {
  bool _isValid() {
    if (_code.length == 1) {
      return false;
    }

    final separatorIndex = _code.indexOf(separator);
    // There must be a single separator at an even index and position should be < SEPARATOR_POSITION.
    if (separatorIndex == -1 ||
        separatorIndex != _code.lastIndexOf(separator) ||
        separatorIndex > separatorPosition ||
        separatorIndex.isOdd) {
      return false;
    }

    // We can have an even number of padding characters before the separator,
    // but then it must be the final character.
    if (_code.contains(padding)) {
      // Short codes cannot have padding.
      if (separatorIndex < separatorPosition) {
        return false;
      }
      // Not allowed to start with them!
      if (_code.indexOf(padding) == 0) {
        return false;
      }
      // There can only be one group and it must have even length.
      final padMatch = RegExp('($padding+)').allMatches(_code).toList();
      if (padMatch.length != 1) {
        return false;
      }
      final matchLength = padMatch.first.group(0)!.length;
      if (matchLength.isOdd || matchLength > separatorPosition - 2) {
        return false;
      }
      // If the code is long enough to end with a separator, make sure it does.
      if (!_code.endsWith(separator)) {
        return false;
      }
    }
    // If there are characters after the separator, make sure there isn't just
    // one of them (not legal).
    if (_code.length - separatorIndex - 1 == 1) {
      return false;
    }

    // Check code contains only valid characters.
    return _code.codeUnits
        .every((ch) => !(ch > decodeTable.length || decodeTable[ch] < -1));
  }

  /// Determines if the [_code] is a valid short code.
  ///
  /// A short Open Location Code is a sequence created by removing four or more
  /// digits from an Open Location Code. It must include a separator character.
  bool isShort() {
    // If there are less characters than expected before the SEPARATOR.
    if (_code.contains(separator) &&
        _code.indexOf(separator) < separatorPosition) {
      return true;
    }
    return false;
  }

  /// Determines if the [_code] is a valid full Open Location Code.
  ///
  /// Not all possible combinations of Open Location Code characters decode to
  /// valid latitude and longitude values. This checks that a code is valid
  /// and also that the latitude and longitude values are legal. If the prefix
  /// character is present, it must be the first character. If the separator
  /// character is present, it must be after four characters.
  bool isFull() {
    // If it's short, it's not full.
    if (isShort()) {
      return false;
    }
    // Work out what the first latitude character indicates for latitude.
    final firstLatValue = decodeTable[_code.codeUnitAt(0)] * encodingBase;
    if (firstLatValue >= latitudeMax * 2) {
      // The code would decode to a latitude of >= 90 degrees.
      return false;
    }
    if (_code.length > 1) {
      // Work out what the first longitude character indicates for longitude.
      final firstLngValue = decodeTable[_code.codeUnitAt(1)] * encodingBase;
      if (firstLngValue >= longitudeMax * 2) {
        // The code would decode to a longitude of >= 180 degrees.
        return false;
      }
    }
    return true;
  }
}
