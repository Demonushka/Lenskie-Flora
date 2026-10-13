import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../logic/species_filter.dart';
import '../models/labels.dart';
import '../models/species.dart';
import '../state/progress_controller.dart';
import '../widgets/species_image.dart';
import 'key_screen.dart';
import 'species_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  SpeciesFilter _filter = const SpeciesFilter();

  @override
  Widget build(BuildContext context) {
    final all = context.read<ContentRepository>().species;
    final progress = context.watch<ProgressController>();
    final list = _filter.apply(all);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редкие виды парка'),
        actions: [
          Badge(
            isLabelVisible: _filter.activeCount > 0,
            label: Text('${_filter.activeCount}'),
            child: IconButton(
              tooltip: 'Фильтры по признакам',
              icon: const Icon(Icons.tune),
              onPressed: _openFilters,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Название, латынь или семейство',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (q) => setState(() => _filter = _filter.copyWith(query: q.trim())),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KeyScreen())),
        icon: const Icon(Icons.quiz_outlined),
        label: const Text('Пошаговый определитель'),
      ),
      body: list.isEmpty
          ? _EmptyResult(onReset: () => setState(() => _filter = const SpeciesFilter()))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: list.length,
              itemBuilder: (_, i) => _SpeciesTile(
                species: list[i],
                identified: progress.identified.contains(list[i].id),
              ),
            ),
    );
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<SpeciesFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(initial: _filter),
    );
    if (result != null) setState(() => _filter = result);
  }
}

class _SpeciesTile extends StatelessWidget {
  final Species species;
  final bool identified;
  const _SpeciesTile({required this.species, required this.identified});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SpeciesDetailScreen(species: species)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(tag: 'sp_${species.id}', child: SpeciesThumb(species: species)),
                  Positioned(left: 6, top: 6, child: StatusBadge(species: species, dense: true)),
                  if (identified)
                    const Positioned(
                      right: 6,
                      top: 6,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.verified, color: Color(0xFF2E7D32), size: 22),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(species.nameRu,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(species.nameLat.split(' ').take(2).join(' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  final VoidCallback onReset;
  const _EmptyResult({required this.onReset});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.search_off, size: 64),
            const SizedBox(height: 12),
            const Text('Нет видов с такими признаками', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onReset, child: const Text('Сбросить фильтры')),
          ]),
        ),
      );
}

class _FilterSheet extends StatefulWidget {
  final SpeciesFilter initial;
  const _FilterSheet({required this.initial});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late SpeciesFilter f = widget.initial;

  Set<String> _toggle(Set<String> s, String v) => s.contains(v) ? ({...s}..remove(v)) : {...s, v};

  Widget _group(String title, Map<String, String> labels, Set<String> selected,
      SpeciesFilter Function(Set<String>) update) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final e in labels.entries)
          FilterChip(
            label: Text(e.value),
            selected: selected.contains(e.key),
            avatar: labels == flowerColorLabels
                ? CircleAvatar(backgroundColor: flowerColorSwatches[e.key], radius: 8)
                : null,
            onSelected: (_) => setState(() => f = update(_toggle(selected, e.key))),
          ),
      ]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, controller) => Column(children: [
        Expanded(
          child: ListView(controller: controller, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            Text('Фильтры по признакам', style: Theme.of(context).textTheme.headlineSmall),
            _group('Окраска цветка', flowerColorLabels, f.colors, (s) => f.copyWith(colors: s)),
            _group('Форма листа', leafShapeLabels, f.leafShapes, (s) => f.copyWith(leafShapes: s)),
            _group('Высота растения', heightClassLabels, f.heights, (s) => f.copyWith(heights: s)),
            _group('Местообитание', habitatLabels, f.habitats, (s) => f.copyWith(habitats: s)),
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text('Цветёт в месяце', style: Theme.of(context).textTheme.titleMedium),
            ),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var m = 5; m <= 9; m++)
                ChoiceChip(
                  label: Text(monthNames[m - 1]),
                  selected: f.floweringMonth == m,
                  onSelected: (sel) =>
                      setState(() => f = sel ? f.copyWith(floweringMonth: m) : f.copyWith(clearMonth: true)),
                ),
            ]),
            const SizedBox(height: 24),
          ]),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => f = SpeciesFilter(query: f.query)),
                  child: const Text('Сбросить'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, f),
                  child: const Text('Показать'),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
