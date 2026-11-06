import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
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

  test('a guide material stays with its excursion and file', () async {
    SharedPreferences.setMockInitialValues({});
    final docs = Directory.systemTemp.createTempSync('flora_materials');
    addTearDown(() {
      if (docs.existsSync()) docs.deleteSync(recursive: true);
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => call.method == 'getApplicationDocumentsDirectory' ? docs.path : null,
    );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
    });
    final source = File('${docs.path}/conspect.txt')..writeAsStringSync('Не сходить на осыпь.');
    final tours = ExcursionController(await LocalStore.open());
    final created = await tours.create('Утренний выход');
    final kept = await tours.keepMaterialFile(source.path, 'conspect.txt');
    await tours.addMaterial(
      excursionId: created.id,
      title: 'Рассказ у скалы',
      text: 'Один вид, который группа видит.',
      fileName: kept!.name,
      filePath: kept.path,
    );

    final restored = ExcursionController(LocalStore(await SharedPreferences.getInstance()));
    final material = restored.byId(created.id)!.materials.single;
    expect(material.title, 'Рассказ у скалы');
    expect(material.fileName, 'conspect.txt');
    expect(File(material.filePath!).readAsStringSync(), 'Не сходить на осыпь.');

    await restored.removeMaterial(created.id, material.id);
    expect(restored.byId(created.id)!.materials, isEmpty);
    expect(File(material.filePath!).existsSync(), isFalse);
  });
}
