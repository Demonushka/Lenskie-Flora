import 'dart:math';

import '../models/labels.dart';
import '../models/species.dart';

class QuizQuestion {
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String? speciesId;

  const QuizQuestion({
    required this.text,
    required this.options,
    required this.correctIndex,
    this.explanation = '',
    this.speciesId,
  });
}

const _conductQuestions = [
  QuizQuestion(
    text: 'Вы нашли на тропе цветущее растение из Красной книги. Как правильно поступить?',
    options: [
      'Сфотографировать, не срывая, и сообщить о находке через приложение',
      'Сорвать один цветок для гербария',
      'Выкопать и пересадить в безопасное место',
      'Огородить растение ветками',
    ],
    correctIndex: 0,
    explanation: 'Редкие растения нельзя срывать и выкапывать. Фото и координаты помогут научному отделу парка.',
  ),
  QuizQuestion(
    text: 'Почему опасно сходить с троп на склонах и тукуланах?',
    options: [
      'Вытаптывание разрушает хрупкий растительный покров',
      'Это никак не влияет на природу',
      'Только потому, что можно испачкать обувь',
      'Растения от этого растут быстрее',
    ],
    correctIndex: 0,
    explanation: 'На скалах, осыпях и песках растительный покров восстанавливается очень долго.',
  ),
  QuizQuestion(
    text: 'Что означает занесение вида в Красную книгу?',
    options: [
      'Вид редкий или находится под угрозой исчезновения и охраняется законом',
      'Вид ядовит',
      'Вид завезён из другой страны',
      'Вид можно собирать только осенью',
    ],
    correctIndex: 0,
    explanation: 'Красная книга — перечень видов, нуждающихся в особой охране.',
  ),
];

class QuizGenerator {
  final List<Species> species;
  final Random _rnd;

  QuizGenerator(this.species, [Random? rnd]) : _rnd = rnd ?? Random();

  List<QuizQuestion> generate({int count = 10}) {
    final pool = <QuizQuestion>[];
    for (final s in species) {
      pool.addAll([
        _family(s),
        _latin(s),
        _flowering(s),
        _habitat(s),
      ].whereType<QuizQuestion>());
    }
    pool.shuffle(_rnd);
    final picked = <QuizQuestion>[];
    final usedSpecies = <String>{};
    for (final q in pool) {
      if (picked.length >= count - 2) break;
      if (usedSpecies.add(q.speciesId!)) picked.add(q);
    }
    picked.addAll(([..._conductQuestions]..shuffle(_rnd)).take(count - picked.length));
    picked.shuffle(_rnd);
    return picked.map(_shuffleOptions).toList();
  }

  QuizQuestion _shuffleOptions(QuizQuestion q) {
    final idx = List.generate(q.options.length, (i) => i)..shuffle(_rnd);
    return QuizQuestion(
      text: q.text,
      options: [for (final i in idx) q.options[i]],
      correctIndex: idx.indexOf(q.correctIndex),
      explanation: q.explanation,
      speciesId: q.speciesId,
    );
  }

  QuizQuestion? _choice(Species s, String text, String correct, Iterable<String> distractorPool,
      {String explanation = ''}) {
    final distractors = distractorPool.where((d) => d != correct && d.isNotEmpty).toSet().toList()
      ..shuffle(_rnd);
    if (distractors.length < 3) return null;
    return QuizQuestion(
      text: text,
      options: [correct, ...distractors.take(3)],
      correctIndex: 0,
      explanation: explanation,
      speciesId: s.id,
    );
  }

  QuizQuestion? _family(Species s) => s.familyShort.isEmpty
      ? null
      : _choice(s, 'К какому семейству относится ${s.nameRu}?', s.familyShort,
          species.map((o) => o.familyShort),
          explanation: '${s.nameRu} — семейство ${s.family}.');

  QuizQuestion? _latin(Species s) => _choice(
        s,
        'Как по-латыни называется ${s.nameRu}?',
        _binomial(s.nameLat),
        species.map((o) => _binomial(o.nameLat)),
        explanation: 'Полное научное название: ${s.nameLat}.',
      );

  QuizQuestion? _flowering(Species s) {
    if (s.floweringMonths.isEmpty) return null;
    return _choice(
      s,
      'Когда цветёт ${s.nameRu}?',
      monthsRange(s.floweringMonths),
      [
        ...species.where((o) => o.floweringMonths.isNotEmpty).map((o) => monthsRange(o.floweringMonths)),
        'апрель', 'сентябрь', 'май – июнь', 'июль – август', 'август – сентябрь',
      ],
    );
  }

  QuizQuestion? _habitat(Species s) {
    if (s.habitats.isEmpty) return null;
    final correct = habitatLabels[s.habitats.first]!;
    final others = habitatLabels.entries
        .where((e) => !s.habitats.contains(e.key))
        .map((e) => e.value);
    return _choice(s, 'Где в природе обычно встречается ${s.nameRu}?', correct, others,
        explanation: s.habitatText);
  }

  static String _binomial(String lat) => lat.split(' ').take(2).join(' ');
}
