import 'dart:math';
import 'dart:typed_data';

class TrainingDataset {
  final String name;
  final String why;

  const TrainingDataset(this.name, this.why);
}

/// Место нейросети в определителе по фото.
/// Весов в приложении нет: без обучающих снимков она не называет вид.
class FlowerVision {
  static const weightsReady = false;

  static const datasets = [
    TrainingDataset(
      'Pl@ntNet-300K',
      '306 тысяч полевых фото, 1081 вид. Много похожих растений и мало снимков у редких.',
    ),
    TrainingDataset(
      'iNaturalist 2021',
      'Полевые наблюдения. Учит отличать близкие виды на живых фото.',
    ),
    TrainingDataset(
      'Oxford 102 Flowers',
      'Крупные фото цветков: форма и окраска венчика.',
    ),
    TrainingDataset(
      'Herbarium 2021',
      'Гербарные листы. Для редких видов это часто единственные снимки.',
    ),
    TrainingDataset(
      'PlantCLEF',
      'Обучение на гербарии и проверка на фото в поле.',
    ),
    TrainingDataset(
      '12 видов Якутии',
      'Свои полевые и гербарные фото редовскии, башмачков, мака якутского и остальных видов списка.',
    ),
  ];

  static String status({required bool hasPhoto, bool matching = false, String? speciesName, int? percent}) {
    if (!hasPhoto) {
      return 'Нейросеть в бете. Снимок сверяется с карточками каталога, само определение ещё разрабатывается.';
    }
    if (matching) return 'Сверяю снимок с карточками каталога.';
    if (speciesName != null && percent != null) {
      return 'Похоже на $speciesName. Предполагаемая вероятность $percent%.';
    }
    return 'Не знаю. На снимке не нашлось цвета, который можно сравнить с карточками.';
  }
}

class CardDecision {
  final String? speciesId;
  const CardDecision(this.speciesId);
  bool get known => speciesId != null;
}

class CardGuess {
  final String speciesId;
  final double probability;
  const CardGuess(this.speciesId, this.probability);
}

/// Ближайшая карточка и её доля среди всех карточек каталога.
/// Доля считается по сходству цвета: чем сильнее отрыв, тем выше вероятность.
CardGuess? guessCard(Map<String, double> scores) {
  if (scores.isEmpty) return null;
  final ranked = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  if (ranked.first.value <= 0) return null;
  const temperature = 0.04;
  final maxScore = ranked.first.value;
  var total = 0.0;
  final weights = <double>[];
  for (final entry in ranked) {
    final weight = exp((entry.value - maxScore) / temperature);
    weights.add(weight);
    total += weight;
  }
  if (total == 0) return null;
  return CardGuess(ranked.first.key, weights.first / total);
}

/// Один вид остаётся, только если карточка явно ближе следующей.
CardDecision decideCard(Map<String, double> scores) {
  if (scores.isEmpty) return const CardDecision(null);
  final ranked = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final best = ranked.first;
  final second = ranked.length > 1 ? ranked[1].value : 0.0;
  if (best.value >= 0.55 && best.value - second >= 0.08) return CardDecision(best.key);
  return const CardDecision(null);
}

const cardGrid = 8;

List<double> cardSignature(Uint8List rgba, int width, int height) {
  final cells = cardGrid * cardGrid;
  final sum = List<double>.filled(cells * 3, 0);
  final count = List<int>.filled(cells, 0);
  for (var y = 0; y < height; y++) {
    final gy = y * cardGrid ~/ height;
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      final r = rgba[i];
      final g = rgba[i + 1];
      final b = rgba[i + 2];
      final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
      final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
      if (maxC > 245 || maxC - minC < 18) continue;
      final cell = gy * cardGrid + x * cardGrid ~/ width;
      sum[cell * 3] += r;
      sum[cell * 3 + 1] += g;
      sum[cell * 3 + 2] += b;
      count[cell]++;
    }
  }
  return [
    for (var cell = 0; cell < cells; cell++) ...[
      count[cell] == 0 ? 0.0 : sum[cell * 3] / count[cell] / 255,
      count[cell] == 0 ? 0.0 : sum[cell * 3 + 1] / count[cell] / 255,
      count[cell] == 0 ? 0.0 : sum[cell * 3 + 2] / count[cell] / 255,
    ],
  ];
}

double cardSimilarity(List<double> a, List<double> b) {
  var dot = 0.0;
  var left = 0.0;
  var right = 0.0;
  for (var i = 0; i < a.length && i < b.length; i++) {
    dot += a[i] * b[i];
    left += a[i] * a[i];
    right += b[i] * b[i];
  }
  if (left == 0 || right == 0) return 0;
  return dot / (sqrt(left) * sqrt(right));
}
