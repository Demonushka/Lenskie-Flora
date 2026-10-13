import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/species.dart';

class ContentRepository {
  final List<Species> species;
  final ParkMap map;

  ContentRepository({required this.species, required this.map});

  static Future<ContentRepository> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final speciesJson = jsonDecode(await b.loadString('assets/data/species.json')) as List;
    final mapJson = jsonDecode(await b.loadString('assets/data/park_map.json')) as Map<String, dynamic>;
    final list = speciesJson
        .map((e) => Species.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.nameRu.compareTo(b.nameRu));
    return ContentRepository(species: list, map: ParkMap.fromJson(mapJson));
  }

  Species? byId(String id) {
    for (final s in species) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<Species> inZone(String zoneId) =>
      species.where((s) => s.parkZones.contains(zoneId)).toList();
}
