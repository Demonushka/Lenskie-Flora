import 'dart:io';

import 'package:geolocator/geolocator.dart';

/// Android uses the phone's own GPS. The default path goes through Google
/// Play services and fails offline or on phones that do not have them.
LocationSettings locationFixSettings({bool? android}) {
  final useAndroid = android ?? Platform.isAndroid;
  if (useAndroid) {
    return AndroidSettings(
      accuracy: LocationAccuracy.high,
      forceLocationManager: true,
      timeLimit: const Duration(seconds: 45),
    );
  }
  return const LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 45),
  );
}

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
        locationSettings: locationFixSettings(),
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
