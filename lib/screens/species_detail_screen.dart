import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../models/labels.dart';
import '../models/species.dart';
import '../state/progress_controller.dart';
import '../widgets/plant_sketch.dart';
import '../widgets/species_image.dart';
import 'report_screen.dart';

class SpeciesDetailScreen extends StatelessWidget {
  final Species species;
  const SpeciesDetailScreen({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = context.watch<ProgressController>();
    final zones = context.read<ContentRepository>().map.zones;
    final s = species;
    final identified = progress.identified.contains(s.id);
    final seen = progress.seen.containsKey(s.id);
    final zoneNames = zones.where((z) => s.parkZones.contains(z.id)).map((z) => z.name).toList();

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Hero(tag: 'sp_${s.id}', child: SpeciesThumb(species: s)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(children: [
            Text(s.nameRu, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(s.nameLat, style: theme.textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 4),
            Text('Семейство: ${s.family}', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            _StatusCard(species: s),
            if (identified)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Chip(
                  avatar: Icon(Icons.verified, color: Color(0xFF2E7D32)),
                  label: Text('Вы определили этот вид'),
                ),
              ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(seen ? Icons.check_box : Icons.check_box_outline_blank),
                  label: Text(seen ? 'В чек-листе' : 'Отметить встречу'),
                  onPressed: () => progress.toggleSeen(s.id),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Сообщить'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReportScreen(initialSpeciesId: s.id)),
                  ),
                ),
              ),
            ]),
            if (s.photos.isNotEmpty) ...[
              _Section('Фотографии'),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: s.photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => _PhotoTile(photo: s.photos[i]),
                ),
              ),
            ],
            _Section('Схема для определения'),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: PlantSketch(species: s, height: 200),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _Trait(Icons.straighten, '${s.heightMin}–${s.heightMax} см'),
              _Trait(Icons.eco_outlined, leafShapeLabels[s.leafShape] ?? s.leafShape),
              for (final c in s.flowerColors)
                Chip(
                  avatar: CircleAvatar(backgroundColor: flowerColorSwatches[c], radius: 8),
                  label: Text(flowerColorLabels[c] ?? c),
                ),
            ]),
            _Section('Описание'),
            _Para(s.descGeneral),
            _Labeled('Листья', s.descLeaves),
            _Labeled('Цветок', s.descFlower),
            _Labeled('Плод', s.descFruit),
            _Section('Где растёт'),
            _Para(s.habitatText),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final h in s.habitats) _Trait(Icons.terrain, habitatLabels[h] ?? h),
            ]),
            if (zoneNames.isNotEmpty) _Labeled('Зоны парка', zoneNames.join(', ')),
            _Section('Сроки'),
            _Labeled('Цветение', monthsRange(s.floweringMonths)),
            _Labeled('Плодоношение', monthsRange(s.fruitingMonths)),
            _MonthsBar(flowering: s.floweringMonths, fruiting: s.fruitingMonths),
            if (s.features.isNotEmpty) ...[
              _Section('Особенности вида'),
              _Para(s.features),
            ],
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.errorContainer,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(children: [
                  Icon(Icons.do_not_touch_outlined),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Растение охраняется законом. Не срывайте и не выкапывайте его — только фото.'),
                  ),
                ]),
              ),
            ),
            if (s.confidence != 'high') ...[
              const SizedBox(height: 8),
              Text('Примечание: ${confidenceLabels[s.confidence] ?? ''}.',
                  style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 32),
          ]),
        ),
      ]),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Species species;
  const _StatusCard({required this.species});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFEBEE),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Охранный статус', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
          const SizedBox(height: 4),
          Text('Красная книга РФ: ${species.statusRf ?? 'не включён'}'),
          Text('Красная книга РС(Я): ${species.statusRsya ?? 'не включён'}'),
        ]),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final SpeciesPhoto photo;
  const _PhotoTile({required this.photo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => Dialog(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            InteractiveViewer(child: Image.asset(photo.asset)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text([photo.kindLabel, if (photo.credit != null) 'Фото: ${photo.credit}'].join(' · ')),
            ),
          ]),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(children: [
          Image.asset(photo.asset, width: 160, height: 160, fit: BoxFit.cover, cacheWidth: 400),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black45,
              padding: const EdgeInsets.all(4),
              child: Text(photo.kindLabel, style: const TextStyle(color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleLarge),
      );
}

class _Para extends StatelessWidget {
  final String text;
  const _Para(this.text);

  @override
  Widget build(BuildContext context) => text.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        );
}

class _Labeled extends StatelessWidget {
  final String label;
  final String text;
  const _Labeled(this.label, this.text);

  @override
  Widget build(BuildContext context) => text.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: text),
            ]),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
}

class _Trait extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Trait(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Chip(avatar: Icon(icon, size: 18), label: Text(text));
}

class _MonthsBar extends StatelessWidget {
  final List<int> flowering;
  final List<int> fruiting;
  const _MonthsBar({required this.flowering, required this.fruiting});

  @override
  Widget build(BuildContext context) {
    const shown = [4, 5, 6, 7, 8, 9];
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(children: [
        Row(children: [
          for (final m in shown)
            Expanded(
              child: Column(children: [
                Text(monthNames[m - 1].substring(0, 3), style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Container(height: 14, margin: const EdgeInsets.symmetric(horizontal: 2),
                    color: flowering.contains(m) ? const Color(0xFFE57399) : const Color(0xFFEEEEEE)),
                const SizedBox(height: 3),
                Container(height: 14, margin: const EdgeInsets.symmetric(horizontal: 2),
                    color: fruiting.contains(m) ? const Color(0xFF8D6E63) : const Color(0xFFEEEEEE)),
              ]),
            ),
        ]),
        const SizedBox(height: 6),
        const Row(children: [
          _Legend(Color(0xFFE57399), 'цветение'),
          SizedBox(width: 16),
          _Legend(Color(0xFF8D6E63), 'плоды'),
        ]),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend(this.color, this.text);

  @override
  Widget build(BuildContext context) =>
      Row(children: [Container(width: 14, height: 14, color: color), const SizedBox(width: 6), Text(text)]);
}
