import '../models/species.dart';

class SpeciesFilter {
  final String query;
  final Set<String> colors;
  final Set<String> leafShapes;
  final Set<String> heights;
  final Set<String> habitats;
  final int? floweringMonth;

  const SpeciesFilter({
    this.query = '',
    this.colors = const {},
    this.leafShapes = const {},
    this.heights = const {},
    this.habitats = const {},
    this.floweringMonth,
  });

  bool get isEmpty =>
      query.isEmpty &&
      colors.isEmpty &&
      leafShapes.isEmpty &&
      heights.isEmpty &&
      habitats.isEmpty &&
      floweringMonth == null;

  int get activeCount =>
      (colors.isEmpty ? 0 : 1) +
      (leafShapes.isEmpty ? 0 : 1) +
      (heights.isEmpty ? 0 : 1) +
      (habitats.isEmpty ? 0 : 1) +
      (floweringMonth == null ? 0 : 1);

  SpeciesFilter copyWith({
    String? query,
    Set<String>? colors,
    Set<String>? leafShapes,
    Set<String>? heights,
    Set<String>? habitats,
    int? floweringMonth,
    bool clearMonth = false,
  }) =>
      SpeciesFilter(
        query: query ?? this.query,
        colors: colors ?? this.colors,
        leafShapes: leafShapes ?? this.leafShapes,
        heights: heights ?? this.heights,
        habitats: habitats ?? this.habitats,
        floweringMonth: clearMonth ? null : (floweringMonth ?? this.floweringMonth),
      );

  bool matches(Species s) {
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      if (!s.nameRu.toLowerCase().contains(q) &&
          !s.nameLat.toLowerCase().contains(q) &&
          !s.family.toLowerCase().contains(q)) {
        return false;
      }
    }
    final sColors = s.flowerColors.isEmpty ? const ['none'] : s.flowerColors;
    if (colors.isNotEmpty && !sColors.any(colors.contains)) return false;
    if (leafShapes.isNotEmpty && !leafShapes.contains(s.leafShape)) return false;
    if (heights.isNotEmpty && !s.heightClasses.any(heights.contains)) return false;
    if (habitats.isNotEmpty && !s.habitats.any(habitats.contains)) return false;
    if (floweringMonth != null && !s.floweringMonths.contains(floweringMonth)) return false;
    return true;
  }

  List<Species> apply(List<Species> all) => all.where(matches).toList();
}
