class SpeciesPhoto {
  final String kind;
  final String asset;
  final String? credit;

  const SpeciesPhoto({required this.kind, required this.asset, this.credit});

  factory SpeciesPhoto.fromJson(Map<String, dynamic> j) => SpeciesPhoto(
        kind: j['kind'] as String,
        asset: j['asset'] as String,
        credit: j['credit'] as String?,
      );

  String get kindLabel => const {
        'general': 'Общий вид',
        'leaves': 'Листья',
        'flower': 'Цветок',
        'fruit': 'Плод',
      }[kind] ??
      kind;
}

class Species {
  final String id;
  final String nameRu;
  final String nameLat;
  final String family;
  final String? statusRf;
  final String? statusRsya;
  final String lifeForm;
  final int? heightMin;
  final int? heightMax;
  final List<String> flowerColors;
  final String leafShape;
  final List<String> habitats;
  final List<int> floweringMonths;
  final List<int> fruitingMonths;
  final String descGeneral;
  final String descLeaves;
  final String descFlower;
  final String descFruit;
  final String habitatText;
  final String features;
  final List<String> parkZones;
  final List<SpeciesPhoto> photos;
  final List<String> sources;
  final String confidence;

  const Species({
    required this.id,
    required this.nameRu,
    required this.nameLat,
    required this.family,
    this.statusRf,
    this.statusRsya,
    required this.lifeForm,
    required this.heightMin,
    required this.heightMax,
    required this.flowerColors,
    required this.leafShape,
    required this.habitats,
    required this.floweringMonths,
    required this.fruitingMonths,
    this.descGeneral = '',
    this.descLeaves = '',
    this.descFlower = '',
    this.descFruit = '',
    this.habitatText = '',
    this.features = '',
    this.parkZones = const [],
    this.photos = const [],
    this.sources = const [],
    this.confidence = 'medium',
  });

  factory Species.fromJson(Map<String, dynamic> j) {
    final height = (j['heightCm'] as Map?) ?? const {};
    List<String> strings(String key) =>
        ((j[key] as List?) ?? const []).map((e) => e.toString()).toList();
    List<int> ints(String key) =>
        ((j[key] as List?) ?? const []).map((e) => (e as num).toInt()).toList();
    return Species(
      id: j['id'] as String,
      nameRu: j['nameRu'] as String,
      nameLat: j['nameLat'] as String,
      family: (j['family'] as String?) ?? '',
      statusRf: j['statusRf'] as String?,
      statusRsya: j['statusRsya'] as String?,
      lifeForm: (j['lifeForm'] as String?) ?? 'herb',
      heightMin: (height['min'] as num?)?.toInt(),
      heightMax: (height['max'] as num?)?.toInt(),
      flowerColors: strings('flowerColors'),
      leafShape: (j['leafShape'] as String?) ?? 'lanceolate',
      habitats: strings('habitats'),
      floweringMonths: ints('floweringMonths'),
      fruitingMonths: ints('fruitingMonths'),
      descGeneral: (j['descGeneral'] as String?) ?? '',
      descLeaves: (j['descLeaves'] as String?) ?? '',
      descFlower: (j['descFlower'] as String?) ?? '',
      descFruit: (j['descFruit'] as String?) ?? '',
      habitatText: (j['habitatText'] as String?) ?? '',
      features: (j['features'] as String?) ?? '',
      parkZones: strings('parkZones'),
      photos: ((j['photos'] as List?) ?? const [])
          .map((e) => SpeciesPhoto.fromJson(e as Map<String, dynamic>))
          .toList(),
      sources: strings('sources'),
      confidence: (j['confidence'] as String?) ?? 'medium',
    );
  }

  String get familyShort {
    final i = family.indexOf('(');
    return (i > 0 ? family.substring(0, i) : family).trim();
  }

  List<String> get heightClasses {
    final min = heightMin;
    final max = heightMax;
    if (min == null || max == null) return const ['low', 'mid', 'high'];
    return [
      if (min < 15) 'low',
      if (min <= 50 && max >= 15) 'mid',
      if (max > 50) 'high',
    ];
  }
}

class ParkZone {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final String description;

  const ParkZone({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    this.description = '',
  });

  factory ParkZone.fromJson(Map<String, dynamic> j) => ParkZone(
        id: j['id'] as String,
        name: j['name'] as String,
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        description: (j['description'] as String?) ?? '',
      );
}

class ParkMap {
  final bool approximate;
  final List<ParkZone> zones;
  final List<List<double>> river;

  const ParkMap({required this.approximate, required this.zones, required this.river});

  factory ParkMap.fromJson(Map<String, dynamic> j) => ParkMap(
        approximate: (j['approximate'] as bool?) ?? true,
        zones: ((j['zones'] as List?) ?? const [])
            .map((e) => ParkZone.fromJson(e as Map<String, dynamic>))
            .toList(),
        river: ((j['river'] as List?) ?? const [])
            .map((p) => (p as List).map((v) => (v as num).toDouble()).toList())
            .toList(),
      );
}
