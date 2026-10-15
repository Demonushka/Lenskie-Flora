import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../data/local_store.dart';

class FieldNote {
  final String id;
  final String kind;
  final String text;
  final double? lat;
  final double? lon;
  final String createdAt;
  final String? speciesId;
  final String? phenophase;
  final String? abundance;
  final String? photoPath;

  const FieldNote({
    required this.id,
    required this.kind,
    required this.text,
    required this.createdAt,
    this.lat,
    this.lon,
    this.speciesId,
    this.phenophase,
    this.abundance,
    this.photoPath,
  });

  bool get isPlant => kind == 'plant';

  factory FieldNote.fromJson(Map<String, dynamic> json) => FieldNote(
        id: json['id'] as String,
        kind: json['kind'] as String? ?? 'plant',
        text: json['text'] as String? ?? '',
        lat: (json['lat'] as num?)?.toDouble(),
        lon: (json['lon'] as num?)?.toDouble(),
        createdAt: json['createdAt'] as String? ?? '',
        speciesId: json['speciesId'] as String?,
        phenophase: json['phenophase'] as String?,
        abundance: json['abundance'] as String?,
        photoPath: json['photoPath'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'text': text,
        'lat': lat,
        'lon': lon,
        'createdAt': createdAt,
        'speciesId': speciesId,
        'phenophase': phenophase,
        'abundance': abundance,
        'photoPath': photoPath,
      };

  String get kindLabel => const {
        'plant': 'Растение',
        'territory': 'Состояние территории',
        'problem': 'Проблема',
      }[kind] ??
      kind;
}

class ObservationController extends ChangeNotifier {
  static const _key = 'observations_v1';
  final LocalStore _store;
  final List<FieldNote> notes = [];

  ObservationController(this._store) {
    final raw = _store.readJson(_key)?['notes'];
    if (raw is List) {
      notes.addAll(raw.map((e) => FieldNote.fromJson((e as Map).cast<String, dynamic>())));
    }
  }

  List<FieldNote> get plants => notes.where((note) => note.isPlant).toList();

  List<FieldNote> get reports => notes.where((note) => !note.isPlant).toList();

  Future<void> add({
    required String kind,
    required String text,
    double? lat,
    double? lon,
    String? speciesId,
    String? phenophase,
    String? abundance,
    String? photoPath,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final storedPhoto = await _storedPhoto(photoPath, id);
    notes.insert(
      0,
      FieldNote(
        id: id,
        kind: kind,
        text: text.trim(),
        lat: lat,
        lon: lon,
        createdAt: DateTime.now().toIso8601String(),
        speciesId: speciesId,
        phenophase: phenophase,
        abundance: abundance,
        photoPath: storedPhoto,
      ),
    );
    await _persist();
  }

  Future<void> update({
    required String id,
    required String kind,
    required String text,
    double? lat,
    double? lon,
    String? speciesId,
    String? phenophase,
    String? abundance,
    String? photoPath,
  }) async {
    final index = notes.indexWhere((note) => note.id == id);
    if (index < 0) return;
    final current = notes[index];
    notes[index] = FieldNote(
      id: current.id,
      kind: kind,
      text: text.trim(),
      lat: lat,
      lon: lon,
      createdAt: current.createdAt,
      speciesId: speciesId,
      phenophase: phenophase,
      abundance: abundance,
      photoPath: await _storedPhoto(photoPath, current.id),
    );
    await _persist();
  }

  Future<void> remove(String id) async {
    final before = notes.length;
    notes.removeWhere((note) => note.id == id);
    if (notes.length != before) await _persist();
  }

  Future<void> _persist() async {
    notifyListeners();
    await _store.writeJson(_key, {'notes': notes.map((n) => n.toJson()).toList()});
  }

  Future<String?> _storedPhoto(String? photoPath, String id) async {
    if (photoPath == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final folder = '${dir.path}${Platform.pathSeparator}';
    if (photoPath.startsWith(folder)) return photoPath;
    final ext = photoPath.contains('.') ? photoPath.substring(photoPath.lastIndexOf('.')) : '.jpg';
    final stored = '${folder}note_$id$ext';
    await File(photoPath).copy(stored);
    return stored;
  }
}
