import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lenskie_flora/app.dart';
import 'package:lenskie_flora/data/content_repository.dart';
import 'package:lenskie_flora/data/local_store.dart';
import 'package:lenskie_flora/screens/guide_excursions_screen.dart';
import 'package:lenskie_flora/screens/guide_home_screen.dart';
import 'package:lenskie_flora/services/sync_service.dart';
import 'package:lenskie_flora/state/excursion_controller.dart';
import 'package:lenskie_flora/state/outbox_controller.dart';
import 'package:lenskie_flora/state/progress_controller.dart';
import 'package:lenskie_flora/state/session_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository content;

  setUpAll(() async {
    content = await ContentRepository.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ExcursionController> pumpGuide(WidgetTester tester) async {
    final store = await LocalStore.open();
    final session = SessionController(store)..role = 'guide';
    final tours = ExcursionController(store);
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider.value(value: content),
        ChangeNotifierProvider(create: (_) => ProgressController(store, totalSpecies: content.species.length)),
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider(create: (_) => OutboxController(store, SyncService())),
        ChangeNotifierProvider.value(value: tours),
      ],
      child: const LenskieFloraApp(),
    ));
    await tester.pump();
    return tours;
  }

  Future<void> openMaterials(WidgetTester tester) async {
    final tile = find.text('Экскурсионные\nматериалы');
    final list = find.descendant(of: find.byType(GuideHomeScreen), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(tile, 200, scrollable: list);
    await tester.drag(list, const Offset(0, -160));
    await tester.pump();
    await tester.tap(tile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('an empty excursion name asks for a title', (tester) async {
    await pumpGuide(tester);
    await tester.tap(find.text('Экскурсии'));
    await tester.pump();

    final create = find.descendant(
      of: find.byType(GuideExcursionsScreen),
      matching: find.widgetWithText(FilledButton, 'Создать экскурсию'),
    );
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pump();

    expect(find.text('Требуется название экскурсии'), findsOneWidget);
    expect(find.text('Пока нет своих экскурсий.'), findsOneWidget);

    await tester.enterText(
      find.descendant(of: find.byType(GuideExcursionsScreen), matching: find.byType(TextField)),
      '   ',
    );
    await tester.tap(create);
    await tester.pump();
    expect(find.text('Требуется название экскурсии'), findsOneWidget);
    expect(find.text('Пока нет своих экскурсий.'), findsOneWidget);
  });

  testWidgets('a guide can attach a note to an excursion', (tester) async {
    final tours = await pumpGuide(tester);
    await tours.create('Утренний выход');
    await tester.pump();

    await openMaterials(tester);

    expect(find.text('Своих материалов пока нет.'), findsOneWidget);
    await tester.tap(find.text('Загрузить материал'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Сохранить'));
    await tester.pump();
    expect(find.text('Укажите название материала'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('material-title')), 'Рассказ у скалы');
    await tester.enterText(find.byKey(const Key('material-text')), 'Не сходить на осыпь.');
    await tester.tap(find.text('Сохранить'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Авторский материал'), findsNothing);
    expect(find.text('Рассказ у скалы'), findsOneWidget);
    expect(find.text('Утренний выход'), findsOneWidget);
    expect(tours.items.single.materials.single.text, 'Не сходить на осыпь.');
  });

  testWidgets('uploading a material asks for an excursion first', (tester) async {
    await pumpGuide(tester);
    await openMaterials(tester);

    await tester.tap(find.text('Загрузить материал'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Сначала создайте экскурсию. Материал прикрепляется к ней.'), findsOneWidget);
  });
}
