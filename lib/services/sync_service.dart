import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../state/outbox_controller.dart';

/// Contract: POST {SYNC_URL}/api/v1/{type}, JSON body; reports with photo go as multipart (fields "data" + "photo").
class SyncService {
  static const baseUrl = String.fromEnvironment('SYNC_URL');
  static const apiKey = String.fromEnvironment('SYNC_API_KEY');

  final http.Client _client;

  SyncService([http.Client? client]) : _client = client ?? http.Client();

  bool get enabled => baseUrl.isNotEmpty;

  Map<String, String> get _headers => {
        if (apiKey.isNotEmpty) 'X-Api-Key': apiKey,
      };

  Future<void> send(OutboxItem item, String deviceId) async {
    final uri = Uri.parse('$baseUrl/api/v1/${item.type.path}');
    final body = {...item.toJson(), 'deviceId': deviceId};
    final photo = item.photoPath;
    http.Response res;
    if (photo != null && File(photo).existsSync()) {
      final req = http.MultipartRequest('POST', uri)
        ..headers.addAll(_headers)
        ..fields['data'] = jsonEncode(body)
        ..files.add(await http.MultipartFile.fromPath('photo', photo));
      res = await http.Response.fromStream(await _client.send(req));
    } else {
      res = await _client.post(
        uri,
        headers: {..._headers, 'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(body),
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException('Сервер ответил ${res.statusCode}', uri: uri);
    }
  }
}
