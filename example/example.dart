import 'package:open_location_code/open_location_code.dart';

void main() {
  final code = PlusCode.encode(
    const LatLng(51.3701125, -10.202665625),
  );

  print(code);
}
