import 'package:open_location_code/open_location_code.dart';
import 'package:test/test.dart';
import 'utils.dart';

// code,isValid,isShort,isFull
void checkValidity(String csvLine) {
  final elements = csvLine.split(',');
  final code = elements[0];
  final isValid = elements[1] == 'true';
  final isShort = elements[2] == 'true';
  final isFull = elements[3] == 'true';

  if (isValid) {
    final olc = PlusCode(code);
    expect(olc.isShort(), equals(isShort));
    expect(olc.isFull(), equals(isFull));
  } else {
    expect(() => PlusCode(code), throwsArgumentError);
  }
}

void main() {
  test('Check Validity', () {
    csvLinesFromFile('validityTests.csv').forEach(checkValidity);
  });
}
