import 'dart:convert';

import 'package:crypto/crypto.dart';

/// SHA-256 of the park inspector code. The code itself is not stored.
const inspectorCodeDigest = 'c1f330d0aff31c1c87403f1e4347bcc21aff7c179908723535f2b31723702525';

bool inspectorCodeMatches(String code) {
  final digest = sha256.convert(utf8.encode(code.trim())).toString();
  return digest == inspectorCodeDigest;
}
