import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../models/labels.dart';
import '../models/species.dart';
import '../state/progress_controller.dart';
import '../theme/flora_theme.dart';
import 'species_detail_screen.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final repo = context.read<ContentRepository>();
    final items = <({Species species, String at})>[];
    for (final entry in progress.seen.entries) {
      final species = repo.byId(entry.key);
      if (species != null) items.add((species: species, at: entry.value));
    }
    items.sort((a, b) => b.at.compareTo(a.at));

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Моя коллекция')),
      body: items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Коллекция пока пуста. Отметьте растение в карточке вида.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: moss, fontSize: 16, height: 1.35),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final item = items[index];
                return Material(
                  color: paper,
                  borderRadius: BorderRadius.circular(20),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE7F0E2),
                      child: Icon(Icons.spa, color: forest, size: 18),
                    ),
                    title: Text(item.species.nameRu, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(item.species.nameLat, style: const TextStyle(fontStyle: FontStyle.italic, color: moss)),
                    trailing: Text(_day(item.at), style: const TextStyle(fontSize: 12, color: moss)),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SpeciesDetailScreen(species: item.species)),
                    ),
                  ),
                );
              },
            ),
    );
  }

  static String _day(String iso) {
    final date = DateTime.tryParse(iso)?.toLocal();
    if (date == null) return '';
    return '${date.day} ${monthNames[date.month - 1]}';
  }
}
