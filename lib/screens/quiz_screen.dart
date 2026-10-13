import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../logic/quiz_generator.dart';
import '../state/outbox_controller.dart';
import '../state/progress_controller.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<QuizQuestion> _questions;
  int _index = 0;
  int _correct = 0;
  int? _selected;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _questions = QuizGenerator(context.read<ContentRepository>().species).generate();
    _index = 0;
    _correct = 0;
    _selected = null;
    _finished = false;
  }

  Future<void> _next() async {
    if (_index + 1 < _questions.length) {
      setState(() {
        _index++;
        _selected = null;
      });
      return;
    }
    setState(() => _finished = true);
    await context.read<ProgressController>().recordQuiz(_correct, _questions.length);
    if (!mounted) return;
    await context.read<OutboxController>().add(OutboxType.quiz, {
      'correct': _correct,
      'total': _questions.length,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_finished) {
      return Scaffold(
        appBar: AppBar(title: const Text('Викторина')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.emoji_events, size: 72, color: Color(0xFFF2C94C)),
              Text('$_correct из ${_questions.length}', style: theme.textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(_correct == _questions.length ? 'Блестяще! Вы настоящий эрудит.' : 'Хороший результат! Попробуйте ещё раз.',
                  textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => setState(_start), child: const Text('Пройти ещё раз')),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Готово')),
            ]),
          ),
        ),
      );
    }

    final q = _questions[_index];
    final answered = _selected != null;
    return Scaffold(
      appBar: AppBar(title: Text('Вопрос ${_index + 1} из ${_questions.length}')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        LinearProgressIndicator(value: (_index + (answered ? 1 : 0)) / _questions.length),
        const SizedBox(height: 16),
        Text(q.text, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionButton(
              text: q.options[i],
              state: !answered
                  ? _OptState.idle
                  : i == q.correctIndex
                      ? _OptState.correct
                      : i == _selected
                          ? _OptState.wrong
                          : _OptState.idle,
              onTap: answered
                  ? null
                  : () => setState(() {
                        _selected = i;
                        if (i == q.correctIndex) _correct++;
                      }),
            ),
          ),
        if (answered) ...[
          if (q.explanation.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(q.explanation, style: theme.textTheme.bodyLarge),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _next,
            child: Text(_index + 1 < _questions.length ? 'Дальше' : 'Результат'),
          ),
        ],
      ]),
    );
  }
}

enum _OptState { idle, correct, wrong }

class _OptionButton extends StatelessWidget {
  final String text;
  final _OptState state;
  final VoidCallback? onTap;
  const _OptionButton({required this.text, required this.state, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _OptState.correct => const Color(0xFFC8E6C9),
      _OptState.wrong => const Color(0xFFFFCDD2),
      _OptState.idle => null,
    };
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: color,
        disabledForegroundColor: Theme.of(context).colorScheme.onSurface,
        minimumSize: const Size.fromHeight(60),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: onTap ?? () {},
      child: Row(children: [
        Expanded(child: Text(text, style: const TextStyle(fontSize: 17))),
        if (state == _OptState.correct) const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
        if (state == _OptState.wrong) const Icon(Icons.cancel, color: Color(0xFFC62828)),
      ]),
    );
  }
}
