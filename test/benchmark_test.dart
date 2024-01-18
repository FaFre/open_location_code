// ignore_for_file: require_trailing_commas

import 'dart:math';

import 'package:open_location_code/open_location_code.dart';
import 'package:test/test.dart';

void main() {
  test('Benchmarking encode and decode', () {
    final now = DateTime.now();
    final random = Random(now.millisecondsSinceEpoch);
    final testData = <({double lng, double lat, int length, String code})>[];

    for (var i = 0; i < 1000000; i++) {
      var lat = random.nextDouble() * 180 - 90;
      var lng = random.nextDouble() * 360 - 180;
      final exp = pow(10, (random.nextDouble() * 10).toInt());
      lat = (lat * exp).round() / exp;
      lng = (lng * exp).round() / exp;
      var length = 2 + (random.nextDouble() * 13).round();
      if (length < 10 && length.isOdd) {
        length += 1;
      }
      final code = PlusCode.encode(LatLng(lat, lng), codeLength: length);
      code.decode();

      testData.add((lat: lat, lng: lng, length: length, code: code.toString()));
    }

    var stopwatch = Stopwatch()..start();
    for (var i = 0; i < testData.length; i++) {
      PlusCode.encode(LatLng(testData[i].lat, testData[i].lng),
          codeLength: testData[i].length);
    }
    var duration = stopwatch.elapsedMicroseconds;

    print('Encoding benchmark ${testData.length}, duration $duration usec, '
        'average ${duration / testData.length} usec');

    stopwatch = Stopwatch()..start();
    for (var i = 0; i < testData.length; i++) {
      PlusCode(testData[i].code).decode();
    }
    duration = stopwatch.elapsedMicroseconds;
    print('Decoding benchmark ${testData.length}, duration $duration usec, '
        'average ${duration / testData.length} usec');
  });
}
