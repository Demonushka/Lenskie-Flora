import 'package:flutter/foundation.dart';

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
    items.removeWhere((item) => item.id == id);
    await _save();
  }

  Future<void> _save() async {
    notifyListeners();
    await _store.writeJson(_key, {'items': items.map((item) => item.toJson()).toList()});
  }
}
