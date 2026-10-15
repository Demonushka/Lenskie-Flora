import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lenskie_flora/data/local_store.dart';
import 'package:lenskie_flora/state/progress_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a species badge stays locked until the identifier records that species', () async {
    SharedPreferences.setMockInitialValues({});
    final progress = ProgressController(await LocalStore.open(), totalSpecies: 2);
    const names = {'adonis': 'Адонис сибирский', 'iris': 'Ирис гладкий'};

    Achievement badge(String id) =>
        progress.achievements(names).singleWhere((item) => item.speciesId == id);

    expect(badge('adonis').unlocked, isFalse);
    expect(badge('iris').unlocked, isFalse);

    await progress.markIdentified('adonis');

    expect(badge('adonis').unlocked, isTrue);
    expect(badge('iris').unlocked, isFalse);
    expect(progress.achievements(names).singleWhere((item) => item.id == 'first_id').unlocked, isTrue);
  });

  test('marks of species removed from the catalog are not counted', () async {
    SharedPreferences.setMockInitialValues({
      'progress_v1': jsonEncode({
        'identified': ['adonis', 'hericium_coralloides'],
        'seen': {
          'adonis': '2026-01-01T00:00:00.000',
          'iris': '2026-01-02T00:00:00.000',
          'hericium_coralloides': '2026-01-03T00:00:00.000',
          'clavariadelphus_pistillaris': '2026-01-04T00:00:00.000',
        },
      }),
    });
    final progress = ProgressController(await LocalStore.open(), totalSpecies: 2);
    expect(progress.seen.length, 4);

    await progress.retainSpecies({'adonis', 'iris'});

    expect(progress.seen.keys.toSet(), {'adonis', 'iris'});
    expect(progress.identified, {'adonis'});
  });
}
