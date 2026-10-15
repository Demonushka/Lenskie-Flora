import 'dart:math';

import '../models/species.dart';

class ProximityVerdict {
  final bool allowed;
  final String? message;
  final double? distanceKm;

  const ProximityVerdict({required this.allowed, this.message, this.distanceKm});
}

class ParkProximity {
  static const maxAccuracyM = 150.0;
  static const maxAge = Duration(minutes: 3);
  static const maxDistanceKm = 12.0;
  static const duplicateRadiusKm = 0.3;
  static const duplicateWindow = Duration(hours: 12);

  static ProximityVerdict evaluate({
    required double lat,
    required double lon,
    required double accuracyM,
    required DateTime fixTime,
    required DateTime now,
    required bool mocked,
    required ParkMap map,
    List<String> speciesZoneIds = const [],
  }) {
    if (mocked) {
      return const ProximityVerdict(
        allowed: false,
        message: 'Подмена координат не принимается. Запись можно сохранить только с обычного GPS на месте.',
      );
    }
    if (!accuracyM.isFinite || accuracyM <= 0 || accuracyM > maxAccuracyM) {
      final shown = accuracyM.isFinite ? '±${accuracyM.round()} м' : 'неизвестна';
      return ProximityVerdict(
        allowed: false,
        message: 'Точность GPS $shown. Подождите, пока погрешность станет меньше ${maxAccuracyM.round()} м: '
            'издалека список цветов не пополняется.',
      );
    }
    final age = now.difference(fixTime);
    final skewed = age.isNegative && age.abs() > const Duration(minutes: 2);
    if (skewed || age > maxAge) {
      return const ProximityVerdict(
        allowed: false,
        message: 'Координаты устарели. Обновите геолокацию, стоя на месте находки.',
      );
    }

    final places = speciesZoneIds.isEmpty
        ? map.zones
        : map.zones.where((z) => speciesZoneIds.contains(z.id)).toList();
    final distance = places.isEmpty ? _distanceToParkKm(lat, lon, map) : _nearestZoneKm(lat, lon, places);
    if (distance == null || distance > maxDistanceKm) {
      final km = distance == null ? '' : ' Сейчас около ${distance.toStringAsFixed(distance < 10 ? 1 : 0)} км.';
      final where = speciesZoneIds.isEmpty
          ? 'Запись принимается только рядом с территорией парка «Ленские столбы».'
          : 'Этот вид можно отметить только рядом с его участком в парке.';
      return ProximityVerdict(
        allowed: false,
        distanceKm: distance,
        message: '$where$km Так список не засоряют цветами, которых здесь нет.',
      );
    }
    return ProximityVerdict(allowed: true, distanceKm: distance);
  }

  static bool duplicatesNearby({
    required double lat,
    required double lon,
    required String? speciesId,
    required DateTime now,
    required Iterable<({double? lat, double? lon, String? speciesId, DateTime at})> existing,
  }) {
    for (final item in existing) {
      if (item.speciesId != speciesId) continue;
      if (item.lat == null || item.lon == null) continue;
      if (now.difference(item.at) > duplicateWindow) continue;
      if (kmBetween(lat, lon, item.lat!, item.lon!) <= duplicateRadiusKm) return true;
    }
    return false;
  }

  static double kmBetween(double lat1, double lon1, double lat2, double lon2) {
    const earth = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    return 2 * earth * asin(sqrt(a.clamp(0.0, 1.0)));
  }

  static double? _nearestZoneKm(double lat, double lon, List<ParkZone> zones) {
    if (zones.isEmpty) return null;
    var best = double.infinity;
    for (final zone in zones) {
      final km = kmBetween(lat, lon, zone.lat, zone.lon);
      if (km < best) best = km;
    }
    return best;
  }

  static double? _distanceToParkKm(double lat, double lon, ParkMap map) {
    var best = _nearestZoneKm(lat, lon, map.zones);
    final river = map.river;
    for (var i = 0; i < river.length - 1; i++) {
      final km = _kmToSegment(lat, lon, river[i][0], river[i][1], river[i + 1][0], river[i + 1][1]);
      if (best == null || km < best) best = km;
    }
    return best;
  }

  static double _kmToSegment(
    double lat,
    double lon,
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const metersPerDegLat = 111320.0;
    final metersPerDegLon = metersPerDegLat * cos(lat * pi / 180);
    final x = (lon - lon1) * metersPerDegLon;
    final y = (lat - lat1) * metersPerDegLat;
    final dx = (lon2 - lon1) * metersPerDegLon;
    final dy = (lat2 - lat1) * metersPerDegLat;
    final len2 = dx * dx + dy * dy;
    final t = len2 == 0 ? 0.0 : ((x * dx + y * dy) / len2).clamp(0.0, 1.0);
    final px = x - t * dx;
    final py = y - t * dy;
    return sqrt(px * px + py * py) / 1000;
  }
}
