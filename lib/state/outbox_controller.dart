import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../data/local_store.dart';
import '../services/sync_service.dart';

enum OutboxType {
  report('reports', 'Сообщение о находке'),
  survey('surveys', 'Опрос');

  final String path;
  final String label;
  const OutboxType(this.path, this.label);
}

class OutboxItem {
  final String id;
  final OutboxType type;
  final DateTime createdAt;
  final Map<String, dynamic> payload;
  final String? photoPath;
  DateTime? syncedAt;

  OutboxItem({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.payload,
    this.photoPath,
    this.syncedAt,
  });

  bool get isSynced => syncedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'payload': payload,
        if (photoPath != null) 'photoPath': photoPath,
        if (syncedAt != null) 'syncedAt': syncedAt!.toIso8601String(),
      };

  factory OutboxItem.fromJson(Map<String, dynamic> j) => OutboxItem(
        id: j['id'] as String,
        type: OutboxType.values.byName(j['type'] as String),
        createdAt: DateTime.parse(j['createdAt'] as String),
        payload: (j['payload'] as Map).cast<String, dynamic>(),
        photoPath: j['photoPath'] as String?,
        syncedAt: j['syncedAt'] == null ? null : DateTime.parse(j['syncedAt'] as String),
      );
}

class OutboxController extends ChangeNotifier {
  static const _key = 'outbox_v1';
  final LocalStore _store;
  final SyncService _sync;
  final List<OutboxItem> items = [];
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  bool syncing = false;
  String? lastError;
  DateTime? lastSyncAt;

  OutboxController(this._store, this._sync) {
    final j = _store.readJson(_key);
    if (j != null) {
      final raw = (j['items'] as List?) ?? const [];
      var droppedQuiz = false;
      for (final entry in raw) {
        final map = (entry as Map).cast<String, dynamic>();
        if (map['type'] == 'quiz') {
          droppedQuiz = true;
          continue;
        }
        items.add(OutboxItem.fromJson(map));
      }
      final last = j['lastSyncAt'] as String?;
      lastSyncAt = last == null ? null : DateTime.parse(last);
      if (droppedQuiz) unawaited(_save());
    }
  }

  bool get syncEnabled => _sync.enabled;
  int get pendingCount => items.where((i) => !i.isSynced).length;
  String get deviceId => _store.deviceId;

  void startAutoSync() {
    if (!_sync.enabled) return;
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) syncNow();
    });
    syncNow();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _save() async {
    notifyListeners();
    await _store.writeJson(_key, {
      'items': items.map((i) => i.toJson()).toList(),
      if (lastSyncAt != null) 'lastSyncAt': lastSyncAt!.toIso8601String(),
    });
  }

  Future<OutboxItem> add(OutboxType type, Map<String, dynamic> payload, {String? photoPath}) async {
    String? storedPhoto;
    final now = DateTime.now();
    final id = '${now.microsecondsSinceEpoch}-${deviceId.substring(0, 6)}';
    if (photoPath != null) {
      final dir = await getApplicationDocumentsDirectory();
      final ext = photoPath.contains('.') ? photoPath.substring(photoPath.lastIndexOf('.')) : '.jpg';
      storedPhoto = '${dir.path}${Platform.pathSeparator}report_$id$ext';
      await File(photoPath).copy(storedPhoto);
    }
    final item = OutboxItem(id: id, type: type, createdAt: now, payload: payload, photoPath: storedPhoto);
    items.add(item);
    await _save();
    unawaited(syncNow());
    return item;
  }

  Future<void> syncNow() async {
    if (!_sync.enabled || syncing || pendingCount == 0) return;
    syncing = true;
    lastError = null;
    notifyListeners();
    try {
      for (final item in items.where((i) => !i.isSynced).toList()) {
        await _sync.send(item, deviceId);
        item.syncedAt = DateTime.now();
      }
      lastSyncAt = DateTime.now();
    } catch (e) {
      lastError = e is SocketException ? 'Нет подключения к интернету' : e.toString();
    } finally {
      syncing = false;
      await _save();
    }
  }

  Future<File> exportToFile() async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().substring(0, 19).replaceAll(':', '-');
    final file = File('${dir.path}${Platform.pathSeparator}lenskie_flora_$stamp.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert({
      'deviceId': deviceId,
      'exportedAt': DateTime.now().toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
    }));
    return file;
  }
}
