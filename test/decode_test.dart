import 'package:open_location_code/open_location_code.dart';
import 'package:test/test.dart';
import 'utils.dart';

// code,lat,lng,latLo,lngLo,latHi,lngHi
void checkEncodeDecode(String csvLine) {
  final elements = csvLine.split(',');
  final code = elements[0];
  final len = int.parse(elements[1]);
  final latLo = double.parse(elements[2]);
  final lngLo = double.parse(elements[3]);
  final latHi = double.parse(elements[4]);
  final lngHi = double.parse(elements[5]);
  final codeArea = PlusCode(code).decode();
  expect(codeArea.codeLength, equals(len));
  expect(codeArea.southWest.latitude, closeTo(latLo, 0.001));
  expect(codeArea.northEast.latitude, closeTo(latHi, 0.001));
  expect(codeArea.southWest.longitude, closeTo(lngLo, 0.001));
  expect(codeArea.northEast.longitude, closeTo(lngHi, 0.001));
}

void main() {
  test('Check decode', () {
    csvLinesFromFile('decoding.csv').forEach(checkEncodeDecode);
  });

  test('MaxCodeLength', () {
    // Check that we do not return a code longer than is valid.
    final code = PlusCode.encode(
      const LatLng(51.3701125, -10.202665625),
      codeLength: 1000000,
    );
    expect(code.toString().length, 16);

    // Extend the code with a valid character and make sure it is still valid.
    var tooLongCode = '${code}W';
    expect(() => PlusCode(tooLongCode), returnsNormally);

    // Extend the code with an invalid character and make sure it is invalid.
    tooLongCode = '${code}U';
    expect(() => PlusCode(tooLongCode), throwsArgumentError);
  });
}
