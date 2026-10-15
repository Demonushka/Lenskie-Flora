import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lenskie_flora/data/local_store.dart';
import 'package:lenskie_flora/models/excursion.dart';
import 'package:lenskie_flora/state/excursion_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an excursion keeps its stops, group and progress', () async {
    SharedPreferences.setMockInitialValues({});
    final tours = ExcursionController(await LocalStore.open());
    final created = await tours.create('Утренний выход');
    await tours.update(created.copyWith(
      departure: '09:30',
      durationMinutes: 120,
      meetingPoint: 'Причал',
      participants: ['Анна', 'Пётр'],
      stops: const [
        ExcursionStop(zoneId: 'buotama', speciesIds: ['koeleria_skrjabinii'], theoryId: 'story'),
        ExcursionStop(zoneId: 'diring', done: true),
      ],
    ));

    final restored = ExcursionController(LocalStore(await SharedPreferences.getInstance()));
    final tour = restored.byId(created.id)!;
    expect(tour.title, 'Утренний выход');
    expect(tour.departure, '09:30');
    expect(tour.participants, ['Анна', 'Пётр']);
    expect(tour.stops.map((stop) => stop.zoneId), ['buotama', 'diring']);
    expect(tour.doneCount, 1);
    expect(jsonDecode(jsonEncode(tour.toJson()))['meetingPoint'], 'Причал');
  });
}
