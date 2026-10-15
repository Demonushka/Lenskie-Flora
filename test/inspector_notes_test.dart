import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lenskie_flora/data/local_store.dart';
import 'package:lenskie_flora/screens/inspector_home_screen.dart';
import 'package:lenskie_flora/state/observation_controller.dart';
import 'package:lenskie_flora/theme/flora_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('plant notes and territory reports stay in different lists', () async {
    SharedPreferences.setMockInitialValues({
      'observations_v1': '{"notes":[{"id":"old","kind":"plant","text":"старая запись","createdAt":"2026-06-01T00:00:00.000"}]}',
    });
    final notes = ObservationController(await LocalStore.open());
    expect(notes.plants.single.text, 'старая запись');

    await notes.add(kind: 'plant', text: 'венерин башмачок', speciesId: 'calypso_bulbosa', phenophase: 'flowering', abundance: '2-10', lat: 61.2, lon: 128.0);
    await notes.add(kind: 'problem', text: 'колея на песке', lat: 61.1, lon: 127.9);
    await notes.add(kind: 'territory', text: 'след на тукулане');

    final problem = notes.reports.firstWhere((note) => note.kind == 'problem');
    await notes.update(id: problem.id, kind: 'problem', text: 'свежая колея', lat: problem.lat, lon: problem.lon);
    await notes.remove(notes.reports.firstWhere((note) => note.kind == 'territory').id);

    final restored = ObservationController(LocalStore(await SharedPreferences.getInstance()));
    expect(restored.plants.map((note) => note.text), ['венерин башмачок', 'старая запись']);
    expect(restored.plants.first.speciesId, 'calypso_bulbosa');
    expect(restored.reports.single.text, 'свежая колея');
    expect(restored.reports.single.createdAt, problem.createdAt);
  });

  testWidgets('the inspector tabs do not show each other\'s records', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final notes = ObservationController(await LocalStore.open());
    await notes.add(kind: 'plant', text: 'венерин башмачок', phenophase: 'flowering', abundance: '1');
    await notes.add(kind: 'problem', text: 'колея на песке');

    Future<void> open(Widget screen) async {
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: notes,
        child: MaterialApp(theme: buildFloraTheme(), home: screen),
      ));
    }

    await open(const InspectorNotesScreen());
    expect(find.text('Наблюдения'), findsOneWidget);
    expect(find.text('венерин башмачок'), findsOneWidget);
    expect(find.text('Цветение · 1 растение'), findsOneWidget);
    expect(find.text('колея на песке'), findsNothing);

    await open(const InspectorNotesScreen(reports: true));
    expect(find.text('Отчёты'), findsOneWidget);
    expect(find.text('колея на песке'), findsOneWidget);
    expect(find.text('венерин башмачок'), findsNothing);

    await tester.tap(find.text('колея на песке'));
    await tester.pumpAndSettle();
    expect(find.text('Изменить отчёт'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'свежая колея');
    await tester.ensureVisible(find.text('Сохранить'));
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('свежая колея'), findsOneWidget);
    expect(find.text('колея на песке'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
