import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lenskie_flora/data/content_repository.dart';
import 'package:lenskie_flora/logic/catalog_cards.dart';
import 'package:lenskie_flora/logic/flower_vision.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('the network is present and waits for training photos', () {
    expect(FlowerVision.weightsReady, isFalse);
    expect(FlowerVision.datasets, hasLength(6));
    expect(FlowerVision.status(hasPhoto: false), contains('карточками'));
    expect(FlowerVision.status(hasPhoto: true), contains('Не знаю'));
  });

  test('one clearly closer card stays, a tie does not', () {
    expect(decideCard({'a': 0.91, 'b': 0.70}).speciesId, 'a');
    expect(decideCard({'a': 0.80, 'b': 0.76}).speciesId, isNull);
    expect(decideCard({'a': 0.40, 'b': 0.10}).speciesId, isNull);
  });

  test('a photo still gets the closest card and a probability', () {
    final sure = guessCard({'a': 0.91, 'b': 0.70, 'c': 0.40})!;
    final weak = guessCard({'a': 0.80, 'b': 0.76, 'c': 0.74})!;
    expect(sure.speciesId, 'a');
    expect(weak.speciesId, 'a');
    expect(sure.probability, greaterThan(weak.probability));
    expect(sure.probability, inInclusiveRange(0, 1));
    expect(guessCard({'a': 0, 'b': 0}), isNull);
    expect(FlowerVision.status(hasPhoto: true, speciesName: 'Калипсо', percent: 40), contains('40%'));
  });

  test('the same catalog card is the only match', () async {
    final content = await ContentRepository.load();
    final calypso = content.byId('calypso_bulbosa')!;
    final bytes = (await rootBundle.load(calypso.photos.first.asset)).buffer.asUint8List();
    final scored = await CatalogCards.scores(bytes, content.species);
    final ranked = scored.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    expect(
      decideCard(scored).speciesId,
      'calypso_bulbosa',
      reason: ranked.take(4).map((entry) => '${entry.key}:${entry.value.toStringAsFixed(3)}').join(', '),
    );
  });
}
