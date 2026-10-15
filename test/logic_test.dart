import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lenskie_flora/logic/identification_key.dart';
import 'package:lenskie_flora/logic/quiz_generator.dart';
import 'package:lenskie_flora/logic/species_filter.dart';
import 'package:lenskie_flora/models/labels.dart';
import 'package:lenskie_flora/models/species.dart';

Species sp(String id, {
  String life = 'herb',
  List<String> colors = const ['white'],
  String leaf = 'lanceolate',
  int hMin = 20,
  int hMax = 40,
  List<String> hab = const ['forest'],
  List<int> fl = const [6],
  String family = 'Fam',
}) =>
    Species(
      id: id,
      nameRu: 'Вид $id',
      nameLat: 'Genus $id L.',
      family: '$family (${family}aceae)',
      lifeForm: life,
      heightMin: hMin,
      heightMax: hMax,
      flowerColors: colors,
      leafShape: leaf,
      habitats: hab,
      floweringMonths: fl,
      fruitingMonths: const [8],
    );

void main() {
  final all = [
    sp('a', colors: ['yellow'], leaf: 'oval', hab: ['forest']),
    sp('b', colors: ['pink'], leaf: 'linear', hab: ['steppe'], hMin: 5, hMax: 12),
    sp('c', colors: ['blue'], leaf: 'divided', hab: ['rocks', 'steppe']),
    sp('d', life: 'fern', colors: [], leaf: 'divided', hab: ['rocks'], fl: []),
    sp('e', life: 'shrub', colors: ['white'], leaf: 'oval', hab: ['forest'], hMin: 60, hMax: 150),
  ];

  group('IdentificationKey', () {
    test('every species is reachable by answering truthfully', () {
      for (final target in all) {
        final key = IdentificationKey(all, month: 6);
        var guard = 0;
        while (key.nextQuestion() != null && guard++ < 10) {
          final q = key.nextQuestion()!;
          final value = key.valuesOf(target, q.trait).first;
          key.answer(q.trait, value);
        }
        expect(key.candidates.map((s) => s.id), contains(target.id), reason: target.id);
        expect(key.candidates.length, lessThanOrEqualTo(2), reason: target.id);
      }
    });

    test('"unknown" answer keeps all candidates and moves to next question', () {
      final key = IdentificationKey(all, month: 6);
      final first = key.nextQuestion()!;
      key.answer(first.trait, unknownAnswer);
      expect(key.candidates.length, all.length);
      expect(key.nextQuestion()!.trait, isNot(first.trait));
    });

    test('contradicting answers yield no candidates but near matches', () {
      final key = IdentificationKey(all, month: 6)
        ..answer('lifeForm', 'fern')
        ..answer('habitat', 'forest');
      expect(key.candidates, isEmpty);
      expect(key.nearMatches.map((s) => s.id), containsAll(['a', 'd']));
    });

    test('undo restores previous state', () {
      final key = IdentificationKey(all, month: 6)..answer('lifeForm', 'herb');
      expect(key.candidates.length, 3);
      key.undo();
      expect(key.candidates.length, 5);
      expect(key.canUndo, isFalse);
    });

    test('flower colour is not asked after "not flowering"', () {
      final key = IdentificationKey(all, month: 6)..answer('flowering', 'no');
      for (var q = key.nextQuestion(); q != null; q = key.nextQuestion()) {
        expect(q.trait, isNot('flowerColor'));
        expect(q.trait, isNot('colorCount'));
        key.answer(q.trait, unknownAnswer);
      }
    });
  });

  group('SpeciesFilter', () {
    test('OR within a trait, AND across traits', () {
      final f = const SpeciesFilter(colors: {'yellow', 'blue'}, habitats: {'rocks'});
      expect(f.apply(all).map((s) => s.id), ['c']);
    });

    test('height class and "no flowers" colour', () {
      expect(const SpeciesFilter(heights: {'low'}).apply(all).map((s) => s.id), ['b']);
      expect(const SpeciesFilter(colors: {'none'}).apply(all).map((s) => s.id), ['d']);
    });
  });

  test('QuizGenerator produces valid questions', () {
    final many = [
      for (var i = 0; i < 8; i++)
        sp('s$i', family: 'F${i % 5}', fl: [5 + i % 4, 6 + i % 4], hab: [habitatLabels.keys.elementAt(i % 7)]),
    ];
    final qs = QuizGenerator(many, Random(1)).generate();
    expect(qs.length, 10);
    for (final q in qs) {
      expect(q.options.length, 4);
      expect(q.options.toSet().length, 4, reason: q.text);
      expect(q.correctIndex, inInclusiveRange(0, 3));
    }
  });

  group('assets/data/species.json', () {
    late List<Species> species;
    setUpAll(() {
      final raw = jsonDecode(File('assets/data/species.json').readAsStringSync()) as List;
      species = raw.map((e) => Species.fromJson(e as Map<String, dynamic>)).toList();
    });

    test('contains the red-book cards and no species outside that set', () {
      expect(species.map((s) => s.id).toSet(), {
        'redowskia_sophiifolia',
        'adonis_sibirica',
        'cypripedium_macranthos',
        'cypripedium_calceolus',
        'cypripedium_guttatum',
        'phlojodicarpus_sibiricus',
        'delphinium_grandiflorum',
        'neottia_camtschatea',
        'polygala_sibirica',
        'calypso_bulbosa',
        'iris_laevigata',
        'nuphar_pumila',
        'nymphaea_tetragona',
        'lilium_pensylvanicum',
        'allium_ramosum',
        'allium_prostratum',
        'platanthera_oligantha',
        'papaver_jacuticum',
        'dactylorhiza_fuchsii',
        'parietaria_debilis',
        'gastrolychnis_saxatilis',
        'koeleria_skrjabinii',
        'ephedra_monosperma',
      });
    });

    test('trait codes are valid', () {
      final zones = (jsonDecode(File('assets/data/park_map.json').readAsStringSync())['zones'] as List)
          .map((z) => z['id'])
          .toSet();
      for (final s in species) {
        expect(lifeFormLabels.keys, contains(s.lifeForm), reason: s.id);
        expect(leafShapeLabels.keys, contains(s.leafShape), reason: s.id);
        expect(flowerColorLabels.keys, containsAll(s.flowerColors), reason: s.id);
        expect(habitatLabels.keys, containsAll(s.habitats), reason: s.id);
        expect(zones, containsAll(s.parkZones), reason: s.id);
        expect(s.habitats, isNotEmpty, reason: s.id);
        if (s.heightMin == null || s.heightMax == null) {
          expect(s.heightMin, isNull, reason: s.id);
          expect(s.heightMax, isNull, reason: s.id);
        } else {
          expect(s.heightMax!, greaterThanOrEqualTo(s.heightMin!), reason: s.id);
        }
        expect([...s.floweringMonths, ...s.fruitingMonths].every((m) => m >= 1 && m <= 12), isTrue, reason: s.id);
        expect(s.statusRf != null || s.statusRsya != null, isTrue, reason: '${s.id}: нет охранного статуса');
        for (final p in s.photos) {
          expect(File(p.asset).existsSync(), isTrue, reason: p.asset);
        }
      }
    });

    test('every species can be identified by the key', () {
      for (final target in species) {
        final month = target.floweringMonths.isEmpty ? 6 : target.floweringMonths.first;
        final key = IdentificationKey(species, month: month);
        var guard = 0;
        while (key.nextQuestion() != null && guard++ < 10) {
          final q = key.nextQuestion()!;
          key.answer(q.trait, key.valuesOf(target, q.trait).first);
        }
        expect(key.candidates.map((s) => s.id), [target.id], reason: target.id);
      }
    });

    test('every truthful answer still ends on that one species', () {
      void walk(Species target, IdentificationKey key) {
        final question = key.nextQuestion();
        if (question == null) {
          expect(key.candidates.map((s) => s.id), [target.id], reason: '${target.id} ${key.answers}');
          return;
        }
        final choices = key.valuesOf(target, question.trait).where((value) => question.options.any((option) => option.value == value));
        expect(choices, isNotEmpty, reason: '${target.id} ${question.trait}');
        for (final choice in choices) {
          final next = IdentificationKey(species, month: key.month)..answers.addAll(key.answers);
          next.answer(question.trait, choice);
          walk(target, next);
        }
      }

      for (final month in [1, 6, 10]) {
        for (final target in species) {
          walk(target, IdentificationKey(species, month: month));
        }
      }
    });
  });
}
