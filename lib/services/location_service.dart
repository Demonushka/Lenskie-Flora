import 'package:geolocator/geolocator.dart';

class LocationResult {
  final Position? position;
  final String? error;
  const LocationResult({this.position, this.error});
}

class LocationService {
  static Future<LocationResult> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult(error: 'Включите геолокацию (GPS) в настройках телефона');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return const LocationResult(error: 'Нет разрешения на доступ к геолокации');
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 45),
        ),
      );
      return LocationResult(position: pos);
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return LocationResult(position: last);
      return const LocationResult(
        error: 'Не удалось определить координаты. Выйдите на открытое место и повторите',
      );
    }
  }
}
