import 'package:open_location_code/open_location_code.dart';
import 'package:test/test.dart';
import 'utils.dart';

// full code,lat,lng,shortcode
void checkShortCode(String csvLine) {
  final elements = csvLine.split(',');
  final olc = PlusCode(elements[0]);
  final lat = double.parse(elements[1]);
  final lng = double.parse(elements[2]);
  final shortCode = PlusCode(elements[3]);
  final testType = elements[4];
  if (testType == 'B' || testType == 'S') {
    final short = olc.shorten(LatLng(lat, lng));
    expect(short, equals(shortCode));
  }
  if (testType == 'B' || testType == 'R') {
    final expanded = shortCode.recoverNearest(LatLng(lat, lng));
    expect(expanded, equals(olc));
  }
}

void main() {
  test('Check short codes', () {
    csvLinesFromFile('shortCodeTests.csv').forEach(checkShortCode);
  });
}
