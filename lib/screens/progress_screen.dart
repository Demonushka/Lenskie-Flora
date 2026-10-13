import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../state/progress_controller.dart';
import 'quiz_screen.dart';
import 'species_detail_screen.dart';
import 'survey_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ContentRepository>();
    final p = context.watch<ProgressController>();
    final theme = Theme.of(context);
    final achievements = p.achievements({for (final s in repo.species) s.id: s.nameRu});
    final meta = achievements.where((a) => a.speciesId == null).toList();
    final perSpecies = achievements.where((a) => a.speciesId != null).toList();
    final next = p.nextLevel;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Мои успехи'),
          bottom: const TabBar(tabs: [Tab(text: 'Достижения'), Tab(text: 'Чек-лист')]),
        ),
        body: TabBarView(children: [
          ListView(padding: const EdgeInsets.all(16), children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.level.title, style: theme.textTheme.headlineSmall),
                  Text('${p.points} баллов', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (next != null) ...[
                    LinearProgressIndicator(
                      value: (p.points - p.level.minPoints) / (next.minPoints - p.level.minPoints),
                      minHeight: 10,
                    ),
                    const SizedBox(height: 4),
                    Text('До уровня «${next.title}»: ${next.minPoints - p.points} баллов'),
                  ] else
                    const Text('Высший уровень достигнут!'),
                  const SizedBox(height: 8),
                  Text('Определено видов: ${p.identified.length} из ${repo.species.length}'),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.quiz),
                  label: const Text('Викторина'),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Итоговый опрос'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SurveyScreen(stage: SurveyStage.after)),
                  ),
                ),
              ),
            ]),
            if (p.quizAttempts > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Лучший результат викторины: ${p.quizBest} из ${p.quizBestTotal}'),
              ),
            const SizedBox(height: 16),
            Text('Награды', style: theme.textTheme.titleLarge),
            for (final a in meta) _AchievementTile(a: a),
            const SizedBox(height: 16),
            Text('Значки видов', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
              children: [
                for (final a in perSpecies)
                  InkWell(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => SpeciesDetailScreen(species: repo.byId(a.speciesId!)!))),
                    child: Column(children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: a.unlocked ? const Color(0xFF2E6B3F) : const Color(0xFFE0E0E0),
                        child: Icon(a.unlocked ? Icons.local_florist : Icons.lock_outline,
                            color: a.unlocked ? Colors.white : Colors.black38),
                      ),
                      const SizedBox(height: 4),
                      Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12)),
                    ]),
                  ),
              ],
            ),
          ]),
          _Checklist(),
        ]),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement a;
  const _AchievementTile({required this.a});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: a.unlocked ? const Color(0xFFF2C94C) : const Color(0xFFE0E0E0),
          child: Icon(a.unlocked ? Icons.emoji_events : Icons.lock_outline,
              color: a.unlocked ? Colors.brown : Colors.black38),
        ),
        title: Text(a.title, style: TextStyle(fontWeight: a.unlocked ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(a.description),
      );
}

class _Checklist extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final repo = context.read<ContentRepository>();
    final p = context.watch<ProgressController>();
    return ListView(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Встречено видов: ${p.seen.length} из ${repo.species.length}. '
            'Отмечайте растения, которые увидели во время прогулки.'),
      ),
      for (final s in repo.species)
        CheckboxListTile(
          value: p.seen.containsKey(s.id),
          onChanged: (_) => p.toggleSeen(s.id),
          title: Text(s.nameRu),
          subtitle: Text(
            p.seen.containsKey(s.id)
                ? 'Отмечено ${p.seen[s.id]!.substring(0, 10).split('-').reversed.join('.')}'
                : s.nameLat,
          ),
          secondary: p.identified.contains(s.id) ? const Icon(Icons.verified, color: Color(0xFF2E7D32)) : null,
        ),
    ]);
  }
}
