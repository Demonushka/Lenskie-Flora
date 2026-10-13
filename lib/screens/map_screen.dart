import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../models/species.dart';
import '../services/location_service.dart';
import 'species_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Offset? _me;
  bool _locating = false;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ContentRepository>();
    final map = repo.map;

    return Scaffold(
      appBar: AppBar(title: const Text('Карта-схема парка')),
      floatingActionButton: map.approximate
          ? null
          : FloatingActionButton(
              tooltip: 'Где я?',
              onPressed: _locating ? null : _locate,
              child: _locating ? const CircularProgressIndicator() : const Icon(Icons.my_location),
            ),
      body: Column(children: [
        if (map.approximate)
          const MaterialBanner(
            content: Text('Схема приблизительная и не предназначена для навигации. '
                'Места произрастания показаны с точностью до туристской зоны.'),
            leading: Icon(Icons.info_outline),
            actions: [SizedBox.shrink()],
          ),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            final size = Size(c.maxWidth, c.maxHeight);
            final proj = _Projection(map, size);
            return InteractiveViewer(
              maxScale: 6,
              child: GestureDetector(
                onTapUp: (d) => _onTap(d.localPosition, proj, repo),
                child: CustomPaint(
                  size: size,
                  painter: _MapPainter(
                    map: map,
                    proj: proj,
                    counts: {for (final z in map.zones) z.id: repo.inZone(z.id).length},
                    me: _me,
                    textScaler: MediaQuery.textScalerOf(context),
                  ),
                ),
              ),
            );
          }),
        ),
        SizedBox(
          height: 64,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            children: [
              for (final z in map.zones)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.place, size: 18),
                    label: Text(z.name),
                    onPressed: () => _showZone(z, repo.inZone(z.id)),
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }

  void _onTap(Offset p, _Projection proj, ContentRepository repo) {
    for (final z in repo.map.zones) {
      if ((proj.toScreen(z.lat, z.lon) - p).distance < 36) {
        _showZone(z, repo.inZone(z.id));
        return;
      }
    }
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    final r = await LocationService.current();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (r.position != null) _me = Offset(r.position!.longitude, r.position!.latitude);
    });
    if (r.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.error!)));
    }
  }

  void _showZone(ParkZone z, List<Species> species) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        builder: (_, controller) => ListView(controller: controller, padding: const EdgeInsets.all(16), children: [
          Text(z.name, style: Theme.of(ctx).textTheme.headlineSmall),
          if (z.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(z.description)),
          const SizedBox(height: 12),
          Text(species.isEmpty ? 'Нет данных о редких видах в этой зоне' : 'Редкие виды в зоне (${species.length}):',
              style: Theme.of(ctx).textTheme.titleMedium),
          for (final s in species)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.local_florist),
              title: Text(s.nameRu),
              subtitle: Text(s.nameLat, style: const TextStyle(fontStyle: FontStyle.italic)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => SpeciesDetailScreen(species: s))),
            ),
        ]),
      ),
    );
  }
}

class _Projection {
  late final double minLon, maxLat, kx, scale, ox, oy;

  _Projection(ParkMap map, Size size) {
    final pts = [
      for (final z in map.zones) [z.lat, z.lon],
      ...map.river.map((p) => [p[0], p[1]]),
    ];
    var minLat = pts.map((p) => p[0]).reduce(min), maxLatV = pts.map((p) => p[0]).reduce(max);
    var minLonV = pts.map((p) => p[1]).reduce(min), maxLon = pts.map((p) => p[1]).reduce(max);
    const pad = 0.08;
    minLat -= pad;
    maxLatV += pad;
    minLonV -= pad;
    maxLon += pad;
    minLon = minLonV;
    maxLat = maxLatV;
    kx = cos((minLat + maxLatV) / 2 * pi / 180);
    final w = (maxLon - minLonV) * kx, h = maxLatV - minLat;
    scale = min(size.width / w, size.height / h);
    ox = (size.width - w * scale) / 2;
    oy = (size.height - h * scale) / 2;
  }

  Offset toScreen(double lat, double lon) => Offset(ox + (lon - minLon) * kx * scale, oy + (maxLat - lat) * scale);
}

class _MapPainter extends CustomPainter {
  final ParkMap map;
  final _Projection proj;
  final Map<String, int> counts;
  final Offset? me;
  final TextScaler textScaler;

  _MapPainter({required this.map, required this.proj, required this.counts, this.me, required this.textScaler});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFEFF5E9));

    if (map.river.length >= 2) {
      final path = Path();
      for (var i = 0; i < map.river.length; i++) {
        final p = proj.toScreen(map.river[i][0], map.river[i][1]);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF7FB3E0)
          ..strokeWidth = 14
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      final mid = map.river[map.river.length ~/ 2];
      _label(canvas, proj.toScreen(mid[0], mid[1]) + const Offset(0, 22), 'р. Лена',
          const TextStyle(color: Color(0xFF2B6CB0), fontStyle: FontStyle.italic, fontSize: 14));
    }

    for (final z in map.zones) {
      final c = proj.toScreen(z.lat, z.lon);
      canvas.drawCircle(c, 20, Paint()..color = const Color(0xFF2E6B3F));
      canvas.drawCircle(c, 20, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
      _label(canvas, c, '${counts[z.id] ?? 0}',
          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15));
      _label(canvas, c + const Offset(0, -34), z.name,
          const TextStyle(color: Color(0xFF1B3D24), fontWeight: FontWeight.w600, fontSize: 14,
              backgroundColor: Color(0xCCFFFFFF)));
    }

    if (me != null) {
      final p = proj.toScreen(me!.dy, me!.dx);
      if ((Offset.zero & size).contains(p)) {
        canvas.drawCircle(p, 12, Paint()..color = const Color(0x553B82F6));
        canvas.drawCircle(p, 6, Paint()..color = const Color(0xFF2563EB));
      }
    }
  }

  void _label(Canvas canvas, Offset center, String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      textScaler: textScaler,
    )..layout(maxWidth: 160);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.me != me || old.counts != counts;
}
