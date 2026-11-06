import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../models/labels.dart';
import '../models/species.dart';
import '../state/progress_controller.dart';
import '../state/session_controller.dart';
import '../theme/flora_theme.dart';
import '../widgets/flora_nav_bar.dart';
import '../widgets/plant_sketch.dart';

class SpeciesDetailScreen extends StatelessWidget {
  final Species species;
  const SpeciesDetailScreen({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final zones = context.read<ContentRepository>().map.zones;
    final saved = progress.seen.containsKey(species.id);
    final zoneNames = zones.where((zone) => species.parkZones.contains(zone.id)).map((zone) => zone.name).toList();
    final book = species.statusRf != null || species.statusRsya != null;

    return Scaffold(
      backgroundColor: cream,
      bottomNavigationBar: FloraNavBar(
        index: 1,
        onTap: (index) {
          context.read<SessionController>().selectTab(index);
          Navigator.pop(context);
        },
      ),
      body: Stack(children: [
        ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 20), children: [
        SizedBox(
          height: 280,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(fit: StackFit.expand, children: [
              _Gallery(species: species),
              Positioned(
                right: 12,
                top: 12,
                child: _RoundButton(
                  icon: saved ? Icons.favorite : Icons.favorite_border,
                  onTap: () => progress.toggleSeen(species.id),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(species.nameRu, style: const TextStyle(fontFamily: floraDisplay, fontSize: 32, height: 1.05)),
              Text(species.nameLat, style: const TextStyle(fontStyle: FontStyle.italic, color: moss, fontSize: 16)),
            ]),
          ),
          if (book)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: chipRed, borderRadius: BorderRadius.circular(12)),
              child: const Text('Красная книга', style: TextStyle(color: chipRedText, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _Fact(species.familyShort.isEmpty ? '—' : species.familyShort, 'Семейство')),
          const SizedBox(width: 8),
          Expanded(child: _Fact(
            species.heightMin == null || species.heightMax == null
                ? 'не указана'
                : '${species.heightMin}–${species.heightMax} см',
            'Высота',
          )),
          const SizedBox(width: 8),
          Expanded(child: _Fact(monthsRange(species.floweringMonths), 'Цветение')),
        ]),
        const SizedBox(height: 12),
        _InfoCard(icon: Icons.notes_outlined, title: 'Описание', text: species.descGeneral),
        _InfoCard(icon: Icons.park_outlined, title: 'Местообитание', text: species.habitatText.isEmpty ? _habitats(species) : species.habitatText),
        if (species.features.isNotEmpty) _InfoCard(icon: Icons.eco_outlined, title: 'Особенности', text: species.features),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(22)),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Где встречается', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  zoneNames.isEmpty
                      ? 'Отдельная точка на схеме парка не отмечена.'
                      : zoneNames.join(', '),
                  style: const TextStyle(color: moss, height: 1.3),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: const Color(0xFFE7F0E2), borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.place_outlined, color: forest, size: 32),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => progress.toggleSeen(species.id),
          icon: Icon(saved ? Icons.check : Icons.add),
          label: Text(saved ? 'В коллекции' : 'Добавить в коллекцию'),
        ),
      ]),
        Positioned(
          left: 20,
          top: 16,
          child: _RoundButton(
            icon: Icons.arrow_back,
            tooltip: 'Назад',
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
      ]),
    );
  }

  static String _habitats(Species species) =>
      species.habitats.map((item) => habitatLabels[item] ?? item).join(', ');
}

class _Gallery extends StatefulWidget {
  final Species species;
  const _Gallery({required this.species});

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.species.photos;
    if (photos.isEmpty) return PlantSketch(species: widget.species);
    return Stack(fit: StackFit.expand, children: [
      PageView.builder(
        itemCount: photos.length,
        onPageChanged: (value) => setState(() => _page = value),
        itemBuilder: (_, index) => Image.asset(
          photos[index].asset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => PlantSketch(species: widget.species),
        ),
      ),
      if (photos.length > 1)
        Positioned(
          right: 16,
          bottom: 16,
          child: Text('${_page + 1}/${photos.length}', style: const TextStyle(color: Colors.white)),
        ),
    ]);
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  const _RoundButton({required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: const Color(0xCCFFFFFF),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, color: ink)),
      ),
    );
    final tip = tooltip;
    if (tip == null) return button;
    return Tooltip(message: tip, child: button);
  }
}

class _Fact extends StatelessWidget {
  final String value;
  final String label;
  const _Fact(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text(value, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(fontSize: 12, color: moss)),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _InfoCard({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(20)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: forest, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(text, style: const TextStyle(height: 1.3, color: Color(0xFF3E5348))),
            ]),
          ),
        ]),
      ),
    );
  }
}
