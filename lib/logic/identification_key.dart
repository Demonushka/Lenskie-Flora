import '../models/labels.dart';
import '../models/species.dart';

const unknownAnswer = '?';

class KeyOption {
  final String value;
  final String label;
  final int count;
  const KeyOption(this.value, this.label, this.count);
}

class KeyQuestion {
  final String trait;
  final String title;
  final String hint;
  final List<KeyOption> options;
  const KeyQuestion(this.trait, this.title, this.hint, this.options);
}

class _Trait {
  final String title;
  final String hint;
  final Map<String, String> labels;
  const _Trait(this.title, this.hint, this.labels);
}

const _traits = <String, _Trait>{
  'lifeForm': _Trait('Что это за растение?', 'Посмотрите на стебель: травянистый или одревесневший', lifeFormLabels),
  'flowering': _Trait('Растение сейчас цветёт?', 'Есть ли раскрытые цветки или бутоны', {
    'yes': 'Да, есть цветки',
    'no': 'Нет, цветков не видно',
  }),
  'flowerColor': _Trait('Какого цвета цветки?', 'Выберите основной цвет венчика', flowerColorLabels),
  'leafShape': _Trait('Какие у растения листья?', 'Смотрите на крупные листья у основания стебля', leafShapeLabels),
  'height': _Trait('Какой высоты растение?', 'Оцените примерно, от земли до верхушки', heightClassLabels),
  'habitat': _Trait('Где растёт растение?', 'Выберите место, где вы его нашли', habitatLabels),
};

/// Multi-access key: asks the question that best splits the remaining candidates; "?" skips a trait.
class IdentificationKey {
  final List<Species> all;
  final int month;
  final Map<String, String> answers = {};
  final List<String> _order = [];

  IdentificationKey(this.all, {int? month}) : month = month ?? DateTime.now().month;

  List<String> valuesOf(Species s, String trait) {
    switch (trait) {
      case 'lifeForm':
        return [s.lifeForm];
      case 'flowering':
        return [s.floweringMonths.contains(month) ? 'yes' : 'no'];
      case 'flowerColor':
        return s.flowerColors.isEmpty ? const ['none'] : s.flowerColors;
      case 'leafShape':
        return [s.leafShape];
      case 'height':
        return s.heightClasses;
      case 'habitat':
        return s.habitats;
    }
    return const [];
  }

  int mismatches(Species s) {
    var n = 0;
    answers.forEach((trait, value) {
      if (value != unknownAnswer && !valuesOf(s, trait).contains(value)) n++;
    });
    return n;
  }

  List<Species> get candidates => all.where((s) => mismatches(s) == 0).toList();

  List<Species> get nearMatches => all.where((s) => mismatches(s) == 1).toList();

  bool _applicable(String trait) {
    if (answers.containsKey(trait)) return false;
    if (trait == 'flowerColor' && (answers['flowering'] == 'no' || answers['lifeForm'] == 'fern')) {
      return false;
    }
    if (trait == 'flowering' && answers['lifeForm'] == 'fern') return false;
    return true;
  }

  KeyQuestion? nextQuestion() {
    final pool = candidates;
    if (pool.length <= 1) return null;
    KeyQuestion? best;
    var bestScore = double.infinity;
    for (final entry in _traits.entries) {
      if (!_applicable(entry.key)) continue;
      final counts = <String, int>{};
      for (final s in pool) {
        for (final v in valuesOf(s, entry.key)) {
          counts[v] = (counts[v] ?? 0) + 1;
        }
      }
      if (counts.values.every((c) => c == pool.length)) continue;
      final sum = counts.values.fold<int>(0, (a, b) => a + b);
      final sumSq = counts.values.fold<int>(0, (a, b) => a + b * b);
      final score = sumSq / sum;
      if (score < bestScore) {
        bestScore = score;
        final options = [
          for (final l in entry.value.labels.entries)
            if (counts.containsKey(l.key)) KeyOption(l.key, l.value, counts[l.key]!),
        ];
        best = KeyQuestion(entry.key, entry.value.title, entry.value.hint, options);
      }
    }
    return best;
  }

  void answer(String trait, String value) {
    answers[trait] = value;
    _order.add(trait);
  }

  bool get canUndo => _order.isNotEmpty;

  void undo() {
    if (_order.isEmpty) return;
    answers.remove(_order.removeLast());
  }

  void reset() {
    answers.clear();
    _order.clear();
  }

  int get step => _order.length;

  List<MapEntry<String, String>> get answeredLabels => [
        for (final t in _order)
          MapEntry(
            _traits[t]!.title,
            answers[t] == unknownAnswer ? 'не знаю' : (_traits[t]!.labels[answers[t]] ?? answers[t]!),
          ),
      ];
}
