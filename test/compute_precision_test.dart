import 'package:open_location_code/src/helpers.dart';
import 'package:test/test.dart';

void main() {
  test('Compute precision test', () {
    expect(computeLatitudePrecision(10), 0.000125);
    expect(computeLatitudePrecision(11), 0.000025);
  });
}
