import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lenskie_flora/data/local_store.dart';
import 'package:lenskie_flora/state/progress_controller.dart';
import 'package:lenskie_flora/widgets/achievement_banner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the first identification shows a banner from the top', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final progress = ProgressController(await LocalStore.open(), totalSpecies: 23);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: progress,
      child: MaterialApp(
        builder: (context, child) => AchievementBannerHost(child: child ?? const SizedBox.shrink()),
        home: const Scaffold(body: SizedBox.expand()),
      ),
    ));

    await progress.markIdentified('adonis', nameRu: 'Адонис сибирский');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('ДОСТИЖЕНИЕ'), findsOneWidget);
    expect(find.text('Первый шаг'), findsOneWidget);
    expect(find.text('Определён вид: Адонис сибирский'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2800));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Первый шаг'), findsNothing);
  });
}
