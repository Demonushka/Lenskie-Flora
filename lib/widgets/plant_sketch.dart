import 'dart:math';

import 'package:flutter/material.dart';

import '../models/labels.dart';
import '../models/species.dart';

/// Schematic drawing generated from traits; shown when no photo asset is bundled.
class PlantSketch extends StatelessWidget {
  final Species species;
  final double? height;

  const PlantSketch({super.key, required this.species, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFEAF3E6), _groundColor(species)],
          stops: const [0.78, 0.78],
        ),
      ),
      child: CustomPaint(painter: _PlantPainter(species), size: Size.infinite),
    );
  }

  static Color _groundColor(Species s) {
    if (s.habitats.contains('sand')) return const Color(0xFFE6D3A3);
    if (s.habitats.contains('rocks')) return const Color(0xFFBDB7AE);
    if (s.habitats.contains('wetland')) return const Color(0xFF8DA77A);
    return const Color(0xFFB5C99A);
  }
}

class _PlantPainter extends CustomPainter {
  final Species s;
  _PlantPainter(this.s);

  static const _stemColor = Color(0xFF3E7A3A);
  static const _leafColor = Color(0xFF5C9E4F);

  @override
  void paint(Canvas canvas, Size size) {
    final ground = size.height * 0.78;
    final maxH = size.height * 0.68;
    final avg = ((s.heightMin ?? 20) + (s.heightMax ?? 40)) / 2;
    final plantH = maxH * (0.35 + 0.65 * (min(avg, 120) / 120));
    final cx = size.width / 2;
    final rnd = Random(s.id.hashCode);

    switch (s.lifeForm) {
      case 'fern':
        _fern(canvas, Offset(cx, ground), plantH);
        return;
      case 'shrub':
      case 'subshrub':
      case 'tree':
        final stems = s.lifeForm == 'tree' ? 1 : 3;
        for (var i = 0; i < stems; i++) {
          final dx = (i - (stems - 1) / 2) * size.width * 0.12;
          _stem(canvas, Offset(cx, ground), Offset(cx + dx * 1.6, ground - plantH * (0.85 + rnd.nextDouble() * 0.15)),
              woody: true, rnd: rnd);
        }
        return;
      default:
        _stem(canvas, Offset(cx, ground), Offset(cx, ground - plantH), woody: false, rnd: rnd);
    }
  }

  void _stem(Canvas canvas, Offset base, Offset top, {required bool woody, required Random rnd}) {
    final paint = Paint()
      ..color = woody ? const Color(0xFF7A5A3A) : _stemColor
      ..strokeWidth = woody ? 4 : 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(base.dx + (top.dx - base.dx) * 0.3 + 6, (base.dy + top.dy) / 2, top.dx, top.dy);
    canvas.drawPath(path, paint);

    final len = (base.dy - top.dy);
    if (s.leafShape != 'reduced') {
      final pairs = s.leafShape == 'needle' ? 7 : 3;
      for (var i = 0; i < pairs; i++) {
        final t = 0.15 + i * (0.7 / pairs);
        final p = Offset.lerp(base, top, t)!;
        final leafLen = len * (s.leafShape == 'needle' ? 0.12 : 0.28) * (1 - t * 0.5);
        _leaf(canvas, p, leafLen, -0.6 - rnd.nextDouble() * 0.2);
        _leaf(canvas, p, leafLen, pi + 0.6 + rnd.nextDouble() * 0.2);
      }
    }

    final colors = s.flowerColors.isEmpty ? <String>[] : s.flowerColors;
    if (colors.isNotEmpty) {
      final petal = Paint()..color = flowerColorSwatches[colors.first]!;
      final edge = Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      final r = max(8.0, len * 0.07);
      final flowers = woody ? 3 : 1;
      for (var i = 0; i < flowers; i++) {
        final c = woody ? Offset.lerp(base, top, 0.6 + i * 0.2)! + Offset(i.isEven ? 10 : -10, 0) : top;
        for (var k = 0; k < 5; k++) {
          final a = k * 2 * pi / 5 - pi / 2;
          final pc = c + Offset(cos(a), sin(a)) * r * 0.7;
          canvas.drawCircle(pc, r * 0.6, petal);
          canvas.drawCircle(pc, r * 0.6, edge);
        }
        canvas.drawCircle(
            c, r * 0.4, Paint()..color = colors.length > 1 ? flowerColorSwatches[colors[1]]! : const Color(0xFFE8B23A));
      }
    }
  }

  void _leaf(Canvas canvas, Offset at, double length, double angle) {
    final paint = Paint()..color = _leafColor;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    final w = switch (s.leafShape) {
      'linear' || 'needle' => length * 0.12,
      'lanceolate' => length * 0.25,
      'oval' => length * 0.45,
      'heart' => length * 0.6,
      _ => length * 0.35,
    };
    if (s.leafShape == 'divided' || s.leafShape == 'compound') {
      for (var i = 1; i <= 3; i++) {
        final x = length * i / 3.2;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, -w * 0.5), width: length * 0.28, height: w * 0.7), paint);
        canvas.drawOval(Rect.fromCenter(center: Offset(x, w * 0.5), width: length * 0.28, height: w * 0.7), paint);
      }
      canvas.drawLine(Offset.zero, Offset(length, 0), Paint()..color = _stemColor..strokeWidth = 1.5);
    } else {
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(length * 0.5, -w, length, 0)
        ..quadraticBezierTo(length * 0.5, w, 0, 0);
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  void _fern(Canvas canvas, Offset base, double h) {
    final stem = Paint()
      ..color = _stemColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final leaf = Paint()..color = _leafColor;
    for (final tilt in [-0.45, 0.0, 0.45]) {
      final top = base + Offset(sin(tilt) * h, -cos(tilt) * h);
      canvas.drawLine(base, top, stem);
      for (var i = 1; i < 10; i++) {
        final p = Offset.lerp(base, top, i / 10)!;
        final l = h * 0.16 * (1 - i / 12);
        for (final side in [-1, 1]) {
          canvas.drawOval(
            Rect.fromCenter(center: p + Offset(side * l * 0.6 * cos(tilt), l * 0.2), width: l, height: l * 0.35),
            leaf,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PlantPainter old) => old.s.id != s.id;
}
