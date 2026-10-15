import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lenskie_flora/data/local_store.dart';
import 'package:lenskie_flora/logic/staff_gate.dart';
import 'package:lenskie_flora/screens/role_screen.dart';
import 'package:lenskie_flora/state/session_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('only the park code matches', () {
    expect(inspectorCodeMatches('5555'), isTrue);
    expect(inspectorCodeMatches(' 5555 '), isTrue);
    expect(inspectorCodeMatches('5556'), isFalse);
    expect(inspectorCodeMatches(''), isFalse);
  });

  testWidgets('inspector opens only through the staff code', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.open();
    final session = SessionController(store);
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: session,
      child: const MaterialApp(home: RoleScreen()),
    ));
    await tester.pump();

    expect(find.text('Турист'), findsOneWidget);
    expect(find.text('Гид'), findsOneWidget);
    expect(find.text('Инспектор'), findsNothing);

    await tester.ensureVisible(find.text('Служебный вход'));
    await tester.tap(find.text('Служебный вход'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), '0000');
    await tester.tap(find.text('Войти'));
    await tester.pump();
    expect(find.text('Неверный код'), findsOneWidget);
    expect(session.role, isNull);

    await tester.enterText(find.byType(TextField), '5555');
    await tester.tap(find.text('Войти'));
    await tester.pump();
    expect(session.role, 'inspector');
  });
}
