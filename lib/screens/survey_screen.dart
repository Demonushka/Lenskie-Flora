import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../state/outbox_controller.dart';
import '../state/progress_controller.dart';

enum SurveyStage {
  before('Входной опрос', 'Ответьте на несколько вопросов до знакомства с приложением — так мы поймём, '
      'насколько хорошо посетители знают редкие растения парка.'),
  after('Итоговый опрос', 'Проверьте, что вы узнали, и помогите парку оценить пользу приложения.');

  final String title;
  final String intro;
  const SurveyStage(this.title, this.intro);
}

enum _QType { single, multi, scale, text }

class _Q {
  final String id;
  final String text;
  final _QType type;
  final List<String> options;
  final Set<int> correct;
  final Set<SurveyStage> stages;

  const _Q(this.id, this.text, this.type,
      {this.options = const [], this.correct = const {}, this.stages = const {SurveyStage.before, SurveyStage.after}});
}

List<_Q> _questions(int speciesCount) => [
      const _Q('role', 'Кто вы?', _QType.single,
          options: ['Турист', 'Гид, туроператор', 'Инспектор парка', 'Исследователь, студент', 'Школьник'],
          stages: {SurveyStage.before}),
      const _Q('age', 'Ваш возраст', _QType.single,
          options: ['До 14', '14–17', '18–35', '36–55', 'Старше 55'], stages: {SurveyStage.before}),
      const _Q('first_visit', 'Вы впервые в парке «Ленские столбы»?', _QType.single,
          options: ['Да', 'Нет'], stages: {SurveyStage.before}),
      const _Q('self_rating', 'Насколько хорошо вы знаете редкие растения парка? (1 — совсем не знаю, 5 — отлично)',
          _QType.scale),
      _Q('count', 'Сколько редких видов растений парка описано в приложении?', _QType.single,
          options: ['5', '12', '$speciesCount', '50'], correct: {2}),
      const _Q('forbidden', 'Что нельзя делать с краснокнижными растениями? (несколько ответов)', _QType.multi,
          options: ['Срывать цветы', 'Выкапывать', 'Фотографировать', 'Вытаптывать', 'Собирать семена'],
          correct: {0, 1, 3, 4}),
      const _Q('finding', 'Что делать, если вы нашли редкое растение?', _QType.single, options: [
        'Сорвать и показать гиду',
        'Сфотографировать, не трогая, и сообщить в парк',
        'Ничего, это неважно',
      ], correct: {1}),
      const _Q('ready_report', 'Готовы ли вы сообщать о находках редких растений?', _QType.single,
          options: ['Да', 'Возможно', 'Нет']),
      const _Q('learned', 'Узнали ли вы новое о редких растениях благодаря приложению? (1 — ничего, 5 — очень много)',
          _QType.scale, stages: {SurveyStage.after}),
      const _Q('usability', 'Насколько удобно приложение? (1 — неудобно, 5 — очень удобно)', _QType.scale,
          stages: {SurveyStage.after}),
      const _Q('comment', 'Ваши пожелания (необязательно)', _QType.text, stages: {SurveyStage.after}),
    ];

class SurveyScreen extends StatefulWidget {
  final SurveyStage stage;
  const SurveyScreen({super.key, required this.stage});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  late final List<_Q> _qs = _questions(context.read<ContentRepository>().species.length)
      .where((q) => q.stages.contains(widget.stage))
      .toList();
  final Map<String, dynamic> _answers = {};
  final _comment = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  bool get _complete => _qs.every((q) {
        if (q.type == _QType.text) return true;
        final a = _answers[q.id];
        return a != null && !(a is Set && a.isEmpty);
      });

  int get _knowledgeScore => _qs.where((q) => q.correct.isNotEmpty).where((q) {
        final a = _answers[q.id];
        if (q.type == _QType.multi) return a is Set<int> && a.length == q.correct.length && a.containsAll(q.correct);
        return q.correct.contains(a);
      }).length;

  int get _knowledgeMax => _qs.where((q) => q.correct.isNotEmpty).length;

  Future<void> _submit() async {
    setState(() => _saving = true);
    final outbox = context.read<OutboxController>();
    final progress = context.read<ProgressController>();
    final answers = <String, dynamic>{
      for (final q in _qs)
        if (q.type == _QType.text)
          q.id: _comment.text.trim()
        else if (q.type == _QType.multi)
          q.id: [for (final i in (_answers[q.id] as Set<int>)) q.options[i]]
        else if (q.type == _QType.scale)
          q.id: _answers[q.id]
        else
          q.id: q.options[_answers[q.id] as int],
    };
    await outbox.add(OutboxType.survey, {
      'stage': widget.stage.name,
      'answers': answers,
      'knowledgeScore': _knowledgeScore,
      'knowledgeMax': _knowledgeMax,
      'speciesIdentified': progress.identified.length,
    });
    await progress.completeSurvey(widget.stage.name);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Спасибо!'),
        content: Text('Верных ответов на вопросы о знаниях: $_knowledgeScore из $_knowledgeMax.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = context.watch<ProgressController>().surveyStages.contains(widget.stage.name);
    return Scaffold(
      appBar: AppBar(title: Text(widget.stage.title)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(widget.stage.intro, style: theme.textTheme.bodyLarge),
        if (done)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Вы уже проходили этот опрос. Новые ответы тоже будут учтены.'),
          ),
        for (final q in _qs) ...[
          const SizedBox(height: 20),
          Text(q.text, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _input(q),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _complete && !_saving ? _submit : null,
          child: const Text('Отправить ответы'),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _input(_Q q) {
    switch (q.type) {
      case _QType.single:
        return RadioGroup<int>(
          groupValue: _answers[q.id] as int?,
          onChanged: (v) => setState(() => _answers[q.id] = v),
          child: Column(children: [
            for (var i = 0; i < q.options.length; i++)
              RadioListTile<int>(
                contentPadding: EdgeInsets.zero,
                value: i,
                title: Text(q.options[i]),
              ),
          ]),
        );
      case _QType.multi:
        final sel = (_answers[q.id] as Set<int>?) ?? <int>{};
        return Column(children: [
          for (var i = 0; i < q.options.length; i++)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: sel.contains(i),
              title: Text(q.options[i]),
              onChanged: (v) => setState(() {
                final next = {...sel};
                v == true ? next.add(i) : next.remove(i);
                _answers[q.id] = next;
              }),
            ),
        ]);
      case _QType.scale:
        return SegmentedButton<int>(
          showSelectedIcon: false,
          emptySelectionAllowed: true,
          segments: [for (var i = 1; i <= 5; i++) ButtonSegment(value: i, label: Text('$i'))],
          selected: {if (_answers[q.id] != null) _answers[q.id] as int},
          onSelectionChanged: (s) => setState(() => _answers[q.id] = s.isEmpty ? null : s.first),
        );
      case _QType.text:
        return TextField(controller: _comment, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder()));
    }
  }
}
