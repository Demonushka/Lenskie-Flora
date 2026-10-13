import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../logic/identification_key.dart';
import '../models/species.dart';
import '../state/progress_controller.dart';
import '../widgets/species_image.dart';
import 'report_screen.dart';
import 'species_detail_screen.dart';

class KeyScreen extends StatefulWidget {
  const KeyScreen({super.key});

  @override
  State<KeyScreen> createState() => _KeyScreenState();
}

class _KeyScreenState extends State<KeyScreen> {
  late final IdentificationKey _key = IdentificationKey(context.read<ContentRepository>().species);

  @override
  Widget build(BuildContext context) {
    final question = _key.nextQuestion();
    final candidates = _key.candidates;

    return PopScope(
      canPop: !_key.canUndo,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_key.undo);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(question == null ? 'Результат' : 'Шаг ${_key.step + 1}'),
          actions: [
            if (_key.canUndo)
              IconButton(
                tooltip: 'Начать заново',
                icon: const Icon(Icons.restart_alt),
                onPressed: () => setState(_key.reset),
              ),
          ],
        ),
        body: question == null
            ? _Result(keyState: _key, onUndo: () => setState(_key.undo))
            : _QuestionView(
                question: question,
                remaining: candidates.length,
                total: _key.all.length,
                preview: candidates,
                onAnswer: (v) => setState(() => _key.answer(question.trait, v)),
                onUndo: _key.canUndo ? () => setState(_key.undo) : null,
              ),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  final KeyQuestion question;
  final int remaining;
  final int total;
  final List<Species> preview;
  final ValueChanged<String> onAnswer;
  final VoidCallback? onUndo;

  const _QuestionView({
    required this.question,
    required this.remaining,
    required this.total,
    required this.preview,
    required this.onAnswer,
    this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(padding: const EdgeInsets.all(16), children: [
      LinearProgressIndicator(value: 1 - (remaining - 1) / (total - 1).clamp(1, total)),
      const SizedBox(height: 8),
      Text('Подходит видов: $remaining из $total', style: theme.textTheme.bodyMedium),
      const SizedBox(height: 16),
      Text(question.title, style: theme.textTheme.headlineSmall),
      const SizedBox(height: 4),
      Text(question.hint, style: theme.textTheme.bodyMedium),
      const SizedBox(height: 16),
      for (final o in question.options)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            onPressed: () => onAnswer(o.value),
            child: Row(children: [
              Expanded(child: Text(o.label, style: const TextStyle(fontSize: 18))),
              Text('${o.count}', style: theme.textTheme.labelLarge),
            ]),
          ),
        ),
      OutlinedButton(
        onPressed: () => onAnswer(unknownAnswer),
        child: const Text('Не знаю / не видно'),
      ),
      if (onUndo != null) ...[
        const SizedBox(height: 8),
        TextButton.icon(onPressed: onUndo, icon: const Icon(Icons.undo), label: const Text('Назад')),
      ],
      if (remaining <= 6) ...[
        const SizedBox(height: 16),
        Text('Возможные варианты', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final s in preview)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 90,
                  child: Column(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(width: 90, height: 70, child: SpeciesThumb(species: s)),
                    ),
                    Text(s.nameRu, maxLines: 2, overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                  ]),
                ),
              ),
          ]),
        ),
      ],
    ]);
  }
}

class _Result extends StatelessWidget {
  final IdentificationKey keyState;
  final VoidCallback onUndo;
  const _Result({required this.keyState, required this.onUndo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final candidates = keyState.candidates;
    final near = candidates.isEmpty ? keyState.nearMatches : <Species>[];

    return ListView(padding: const EdgeInsets.all(16), children: [
      if (candidates.isNotEmpty) ...[
        Text(candidates.length == 1 ? 'Скорее всего, это:' : 'Подходящие виды:',
            style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        const Text('Сравните растение с описанием и рисунком. Если совпадает — подтвердите определение.'),
        const SizedBox(height: 12),
        for (final s in candidates) _CandidateCard(species: s),
      ] else ...[
        Text('Точного совпадения нет', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'Возможно, это не редкий вид, или какой-то признак выбран неточно. '
          'Попробуйте вернуться на шаг назад или посмотрите близкие варианты.',
        ),
        const SizedBox(height: 12),
        for (final s in near) _CandidateCard(species: s),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Сообщить о необычной находке'),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen())),
        ),
      ],
      const SizedBox(height: 12),
      Text('Ваши ответы', style: theme.textTheme.titleMedium),
      for (final a in keyState.answeredLabels)
        ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(a.key), subtitle: Text(a.value)),
      TextButton.icon(onPressed: onUndo, icon: const Icon(Icons.undo), label: const Text('Изменить последний ответ')),
    ]);
  }
}

class _CandidateCard extends StatelessWidget {
  final Species species;
  const _CandidateCard({required this.species});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final done = progress.identified.contains(species.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SpeciesDetailScreen(species: species)),
          ),
          child: Row(children: [
            SizedBox(width: 110, height: 110, child: SpeciesThumb(species: species)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(species.nameRu, style: Theme.of(context).textTheme.titleMedium),
                Text(species.nameLat, style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                StatusBadge(species: species, dense: true),
                const SizedBox(height: 4),
                const Text('Открыть карточку ›', style: TextStyle(decoration: TextDecoration.underline)),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: done
              ? const Center(child: Chip(avatar: Icon(Icons.verified), label: Text('Уже определён')))
              : FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Да, это он'),
                  onPressed: () async {
                    final added = await context.read<ProgressController>().markIdentified(species.id);
                    if (!context.mounted || !added) return;
                    final p = context.read<ProgressController>();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(p.isFloraExpert
                          ? 'Поздравляем! Вы — «Знаток флоры Ленских столбов»!'
                          : 'Новый значок: ${species.nameRu} (+${Points.identify} баллов)'),
                    ));
                  },
                ),
        ),
      ]),
    );
  }
}
