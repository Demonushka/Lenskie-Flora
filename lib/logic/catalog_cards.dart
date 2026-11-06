import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../models/species.dart';
import 'flower_vision.dart';

class CatalogCards {
  static final _cache = <String, List<double>>{};

  static Future<List<double>> signatureOf(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 64, targetHeight: 64);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final width = image.width;
    final height = image.height;
    image.dispose();
    return cardSignature(data!.buffer.asUint8List(), width, height);
  }

  static Future<Map<String, double>> scores(Uint8List photo, List<Species> species) async {
    final query = await signatureOf(photo);
    final scores = <String, double>{};
    for (final item in species) {
      await Future<void>.delayed(Duration.zero);
      final asset = item.photos.where((photo) => photo.kind == 'general').firstOrNull?.asset ?? item.photos.firstOrNull?.asset;
      if (asset == null) continue;
      final stored = _cache[item.id] ??= await signatureOf((await rootBundle.load(asset)).buffer.asUint8List());
      scores[item.id] = cardSimilarity(query, stored);
    }
    return scores;
  }

  static Future<CardGuess?> guess(Uint8List photo, List<Species> species) async {
    return guessCard(await scores(photo, species));
  }
}
