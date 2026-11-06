import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../data/local_store.dart';
import '../models/excursion.dart';

class ExcursionController extends ChangeNotifier {
  static const _key = 'excursions_v1';
  final LocalStore _store;
  final List<Excursion> items = [];

  ExcursionController(this._store) {
    final raw = _store.readJson(_key);
    final list = raw?['items'];
    if (list is! List) return;
    for (final entry in list) {
      if (entry is Map) {
        final tour = Excursion.fromJson(entry.cast<String, dynamic>());
        if (tour.id.isNotEmpty && tour.title.isNotEmpty) items.add(tour);
      }
    }
  }

  Excursion? byId(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<Excursion> create(String title) async {
    final tour = Excursion(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
    );
    items.insert(0, tour);
    await _save();
    return tour;
  }

  Future<void> update(Excursion tour) async {
    final index = items.indexWhere((item) => item.id == tour.id);
    if (index < 0) return;
    items[index] = tour;
    await _save();
  }

  Future<void> remove(String id) async {
    final tour = byId(id);
    if (tour != null) {
      for (final item in tour.materials) {
        await _deleteStored(item.filePath);
      }
    }
    items.removeWhere((item) => item.id == id);
    await _save();
  }

  Future<({String path, String name})?> keepMaterialFile(String sourcePath, String name) async {
    final source = File(sourcePath);
    if (!await source.exists()) return null;
    final stored = await _newMaterialPath(name);
    await source.copy(stored);
    return (path: stored, name: _fileName(name));
  }

  Future<({String path, String name})?> keepMaterialBytes(List<int> bytes, String name) async {
    final stored = await _newMaterialPath(name);
    await File(stored).writeAsBytes(bytes, flush: true);
    return (path: stored, name: _fileName(name));
  }

  Future<void> discardKeptFile(String path) => _deleteStored(path);

  Future<void> addMaterial({
    required String excursionId,
    required String title,
    String text = '',
    String? fileName,
    String? filePath,
  }) async {
    final name = title.trim();
    final index = items.indexWhere((item) => item.id == excursionId);
    if (name.isEmpty || index < 0) return;
    final tour = items[index];
    items[index] = tour.copyWith(materials: [
      ...tour.materials,
      ExcursionMaterial(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: name,
        text: text.trim(),
        fileName: fileName,
        filePath: filePath,
      ),
    ]);
    await _save();
  }

  Future<void> removeMaterial(String excursionId, String materialId) async {
    final index = items.indexWhere((item) => item.id == excursionId);
    if (index < 0) return;
    final tour = items[index];
    final removed = tour.materials.where((item) => item.id == materialId);
    for (final item in removed) {
      await _deleteStored(item.filePath);
    }
    items[index] = tour.copyWith(materials: tour.materials.where((item) => item.id != materialId).toList());
    await _save();
  }

  Future<String> _newMaterialPath(String name) async {
    final docs = await getApplicationDocumentsDirectory();
    final folder = Directory('${docs.path}${Platform.pathSeparator}materials');
    await folder.create(recursive: true);
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    return '${folder.path}${Platform.pathSeparator}$id${_extension(name)}';
  }

  Future<void> _deleteStored(String? path) async {
    if (path == null || path.isEmpty) return;
    final docs = await getApplicationDocumentsDirectory();
    final folder = '${docs.path}${Platform.pathSeparator}materials${Platform.pathSeparator}';
    if (!path.startsWith(folder)) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  String _fileName(String name) {
    final base = name.trim();
    if (base.isEmpty) return 'файл';
    return base.split(Platform.pathSeparator).last;
  }

  String _extension(String name) {
    final file = _fileName(name);
    final dot = file.lastIndexOf('.');
    if (dot <= 0 || dot == file.length - 1) return '';
    final ext = file.substring(dot).toLowerCase();
    return ext.length > 8 ? '' : ext;
  }

  Future<void> _save() async {
    notifyListeners();
    await _store.writeJson(_key, {'items': items.map((item) => item.toJson()).toList()});
  }
}
