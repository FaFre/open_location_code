import 'package:latlong2/latlong.dart';
import 'package:open_location_code/open_location_code.dart';
import 'package:test/test.dart';
import 'utils.dart';

// code,lat,lng,latLo,lngLo,latHi,lngHi
void checkEncodeDecode(String csvLine) {
  final elements = csvLine.split(',');
  final lat = double.parse(elements[0]);
  final lng = double.parse(elements[1]);
  final len = int.parse(elements[2]);
  final want = PlusCode(elements[3]);
  final got = PlusCode.encode(LatLng(lat, lng), codeLength: len);
  expect(got, equals(want));
}

void main() {
  test('Check encode decode', () {
    csvLinesFromFile('encoding.csv').forEach(checkEncodeDecode);
  });

  test('MaxCodeLength', () {
    // Check that we do not return a code longer than is valid.
    final code = PlusCode.encode(
      const LatLng(51.3701125, -10.202665625),
      codeLength: 1000000,
    );
    final area = code.decode();
    expect(code.toString().length, 16);
    expect(area.codeLength, 15);

    // Extend the code with a valid character and make sure it is still valid.
    var tooLongCode = '${code}W';
    expect(() => PlusCode(tooLongCode), returnsNormally);

    // Extend the code with an invalid character and make sure it is invalid.
    tooLongCode = '${code}U';
    expect(() => PlusCode(tooLongCode), throwsArgumentError);
  });
}
