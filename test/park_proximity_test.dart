import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lenskie_flora/logic/park_proximity.dart';
import 'package:lenskie_flora/models/species.dart';

void main() {
  final now = DateTime.utc(2026, 7, 14, 6);
  late ParkMap map;

  setUpAll(() {
    map = ParkMap.fromJson(jsonDecode(File('assets/data/park_map.json').readAsStringSync()) as Map<String, dynamic>);
  });

  ProximityVerdict check({
    double lat = 61.17,
    double lon = 127.40,
    double accuracyM = 20,
    DateTime? fixTime,
    bool mocked = false,
    List<String> speciesZoneIds = const [],
  }) {
    return ParkProximity.evaluate(
      lat: lat,
      lon: lon,
      accuracyM: accuracyM,
      fixTime: fixTime ?? now,
      now: now,
      mocked: mocked,
      map: map,
      speciesZoneIds: speciesZoneIds,
    );
  }

  test('a fresh precise fix at a park zone is accepted', () {
    final verdict = check();
    expect(verdict.allowed, isTrue);
    expect(verdict.distanceKm, lessThan(1));
  });

  test('a city far from the park is rejected', () {
    final verdict = check(lat: 62.03, lon: 129.73);
    expect(verdict.allowed, isFalse);
    expect(verdict.message, contains('рядом'));
  });

  test('a species can be recorded only near its own zone', () {
    expect(check(speciesZoneIds: ['labydya']).allowed, isTrue);
    final far = check(lat: 61.17, lon: 128.45, speciesZoneIds: ['labydya']);
    expect(far.allowed, isFalse);
    expect(far.message, contains('участком'));
  });

  test('a coarse, stale or mocked fix is rejected even inside the park', () {
    expect(check(accuracyM: 800).allowed, isFalse);
    expect(check(fixTime: now.subtract(const Duration(minutes: 10))).allowed, isFalse);
    expect(check(mocked: true).allowed, isFalse);
  });

  test('the same flower cannot be filed again from the same spot', () {
    final existing = [
      (lat: 61.1701, lon: 127.4001, speciesId: 'iris_laevigata', at: now.subtract(const Duration(hours: 1))),
    ];
    expect(
      ParkProximity.duplicatesNearby(
        lat: 61.1702,
        lon: 127.4002,
        speciesId: 'iris_laevigata',
        now: now,
        existing: existing,
      ),
      isTrue,
    );
    expect(
      ParkProximity.duplicatesNearby(
        lat: 61.20,
        lon: 127.55,
        speciesId: 'iris_laevigata',
        now: now,
        existing: existing,
      ),
      isFalse,
    );
  });
}
