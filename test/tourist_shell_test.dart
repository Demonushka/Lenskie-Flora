import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lenskie_flora/app.dart';
import 'package:lenskie_flora/screens/profile_screen.dart';
import 'package:lenskie_flora/screens/species_detail_screen.dart';
import 'package:lenskie_flora/data/content_repository.dart';
import 'package:lenskie_flora/data/local_store.dart';
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
    SharedPreferences.setMockInitialValues({});
    content = await ContentRepository.load();
  });

  Future<SessionController> pumpTourist(WidgetTester tester) async {
    final store = await LocalStore.open();
    final session = SessionController(store)..role = 'tourist';
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider.value(value: content),
        ChangeNotifierProvider(
            create: (_) => ProgressController(store,
                totalSpecies: content.species.length)),
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider(
            create: (_) => OutboxController(store, SyncService())),
      ],
      child: const LenskieFloraApp(),
    ));
    await tester.pump();
    return session;
  }

  testWidgets('tourist shell shows the home from the design', (tester) async {
    await pumpTourist(tester);

    expect(find.textContaining('ОПРЕДЕЛИТЬ'), findsWidgets);
    expect(find.text('МОЯ КОЛЛЕКЦИЯ'), findsOneWidget);
    expect(find.text('Профиль'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('МОЯ КОЛЛЕКЦИЯ'));
    await tester.tap(find.text('МОЯ КОЛЛЕКЦИЯ'));
    await tester.pumpAndSettle();
    expect(find.text('Моя коллекция'), findsOneWidget);
    expect(
        find.text('Коллекция пока пуста. Отметьте растение в карточке вида.'),
        findsOneWidget);
    Navigator.of(tester.element(find.text('Моя коллекция'))).pop();
    await tester.pump();

    await tester.tap(find.text('Профиль'));
    await tester.pump();
    expect(find.text('МОЙ ПРОФИЛЬ'), findsOneWidget);
    expect(find.text('Иванов Иван'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Растения'));
    await tester.pump();
    await tester.tap(find.widgetWithText(InkWell, 'Башмачок настоящий'));
    await tester.pumpAndSettle();
    expect(find.byType(SpeciesDetailScreen), findsOneWidget);
    expect(find.text('Семейство'), findsOneWidget);
    await tester.drag(
      find.descendant(
          of: find.byType(SpeciesDetailScreen),
          matching: find.byType(ListView)),
      const Offset(0, -800),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Добавить в коллекцию'), findsWidgets);
    expect(tester.takeException(), isNull);

    Navigator.of(tester.element(find.byType(SpeciesDetailScreen))).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.descendant(
        of: find.byType(TouristShell), matching: find.text('Определить')));
    await tester.pump();
    expect(find.text('ОПРЕДЕЛЕНИЕ ПО ФОТО'), findsOneWidget);
    expect(find.text('НЕЙРОСЕТЬ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile opens the privacy policy', (tester) async {
    final session = await pumpTourist(tester);
    session.selectTab(4);
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Политика конфиденциальности'),
      200,
      scrollable: find.descendant(
          of: find.byType(ProfileScreen), matching: find.byType(Scrollable)),
    );
    await tester.tap(find.text('Политика конфиденциальности'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ничего не отправляет на сервер'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping determine again returns to the start', (tester) async {
    await pumpTourist(tester);
    await tester.tap(find.text('Определить'));
    await tester.pump();
    await tester.tap(find.text('Начать по признакам'));
    await tester.pump();
    expect(
      find.byWidgetPredicate((widget) =>
          widget is RichText &&
          widget.text.toPlainText() == 'Какая форма листьев?'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Назад'));
    await tester.pump();
    expect(find.text('Начать по признакам'), findsOneWidget);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pump();
    expect(find.text('МОЯ КОЛЛЕКЦИЯ'), findsOneWidget);

    await tester.tap(find.text('Растения'));
    await tester.pump();
    await tester.tap(find.widgetWithText(InkWell, 'Башмачок настоящий'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.descendant(
        of: find.byType(SpeciesDetailScreen),
        matching: find.byTooltip('Назад')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SpeciesDetailScreen), findsNothing);

    await tester.tap(find.text('Определить'));
    await tester.pump();
    expect(find.text('Начать по признакам'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) =>
          widget is RichText &&
          widget.text.toPlainText() == 'Какая форма листьев?'),
      findsNothing,
    );
  });

  testWidgets('canceling the rename dialog keeps the name', (tester) async {
    final session = await pumpTourist(tester);
    await tester.tap(find.text('Профиль'));
    await tester.pump();

    await tester.tap(find.byTooltip('Изменить имя'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Как к вам обращаться?'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Как к вам обращаться?'), findsNothing);
    expect(find.text('Иванов Иван'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Изменить имя'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'Петров Пётр');
    await tester.tap(find.text('Сохранить'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Петров Пётр'), findsOneWidget);
    expect(session.displayName, 'Петров Пётр');
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 20)));

  testWidgets('guide home uses the guide copy and pictures', (tester) async {
    final store = await LocalStore.open();
    final session = SessionController(store)..role = 'guide';
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider.value(value: content),
        ChangeNotifierProvider(
            create: (_) => ProgressController(store,
                totalSpecies: content.species.length)),
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider(
            create: (_) => OutboxController(store, SyncService())),
        ChangeNotifierProvider(create: (_) => ExcursionController(store)),
      ],
      child: const LenskieFloraApp(),
    ));
    await tester.pump();

    expect(find.text('Гид'), findsOneWidget);
    expect(find.text('Создать экскурсию'), findsOneWidget);
    expect(find.text('Маршруты и\nточки интереса'), findsOneWidget);
    expect(find.text('Экскурсии'), findsOneWidget);
    expect(find.byType(SvgPicture), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('backing out of the home asks before leaving', (tester) async {
    await pumpTourist(tester);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Выйти из приложения?'), findsOneWidget);
    expect(find.text('МОЯ КОЛЛЕКЦИЯ'), findsOneWidget);
    await tester.tap(find.text('Остаться'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Выйти из приложения?'), findsNothing);
    expect(find.text('МОЯ КОЛЛЕКЦИЯ'), findsOneWidget);
  });
}
