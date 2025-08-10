import 'package:geocoding/geocoding.dart';

Future<String> getAddressFromLatLng(double lat, double lng) async {
  try {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      return '${place.locality}, ${place.administrativeArea}';
    }
  } catch (e) {
    print("Error reverse geocoding: $e");
  }
  return 'Location unavailable';
}
