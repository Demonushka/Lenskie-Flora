import 'package:flutter/foundation.dart';

import '../data/local_store.dart';

class SessionController extends ChangeNotifier {
  static const _key = 'session_v1';
  final LocalStore _store;

  String? role;
  String displayName;
  int tab = 0;
  int identifyGeneration = 0;
  bool handlesBack = false;
  bool Function()? _backHandler;

  SessionController(this._store)
      : role = _store.readJson(_key)?['role'] as String?,
        displayName = _readName(_store);

  static String _readName(LocalStore store) {
    final raw = store.readJson(_key)?['displayName'] as String?;
    if (raw == null || raw.trim().isEmpty) return 'Иванов Иван';
    return raw.trim();
  }

  Future<void> _write() => _store.writeJson(_key, {
        if (role != null) 'role': role,
        'displayName': displayName,
      });

  Future<void> chooseRole(String value) async {
    role = value;
    tab = 0;
    notifyListeners();
    await _write();
  }

  Future<void> clearRole() async {
    role = null;
    tab = 0;
    notifyListeners();
    await _write();
  }

  Future<void> rename(String value) async {
    final next = value.trim();
    if (next.isEmpty) return;
    displayName = next;
    notifyListeners();
    await _write();
  }

  void selectTab(int index) {
    if (role == 'tourist' && index == 2) {
      openIdentify();
      return;
    }
    tab = index;
    notifyListeners();
  }

  void openIdentify() {
    tab = 2;
    identifyGeneration++;
    notifyListeners();
  }

  void bindBack(bool Function()? handler, {required bool handles, bool notify = true}) {
    _backHandler = handler;
    if (handlesBack == handles) return;
    handlesBack = handles;
    if (notify) notifyListeners();
  }

  bool tryBack() => _backHandler?.call() ?? false;
}
