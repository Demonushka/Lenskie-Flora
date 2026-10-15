import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/theory_content.dart';
import '../state/session_controller.dart';
import '../theme/flora_theme.dart';

class TheoryScreen extends StatelessWidget {
  const TheoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<SessionController>().role;
    final lessons = theoryFor(role);
    final staff = role == 'guide' || role == 'inspector';
    final intro = switch (role) {
      'guide' => 'Основа для посетителя и материалы, чтобы вести рассказ на маршруте.',
      'inspector' => 'Основа для посетителя и правила полевого учёта.',
      _ => 'Короткая база: почему растения редкие и как на них смотреть. Карточки видов остаются прежними.',
    };

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Теория')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(intro, style: const TextStyle(color: moss, height: 1.35)),
          const SizedBox(height: 16),
          const _Heading('Основа'),
          for (final lesson in lessons.where((item) => item.roles.contains('tourist'))) _LessonTile(lesson: lesson),
          if (staff) ...[
            const SizedBox(height: 8),
            _Heading(role == 'guide' ? 'Для экскурсии' : 'Для полевой работы'),
            for (final lesson in lessons.where((item) => !item.roles.contains('tourist'))) _LessonTile(lesson: lesson),
          ],
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontFamily: floraDisplay, fontSize: 26, color: ink)),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final TheoryLesson lesson;
  const _LessonTile({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: paper,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TheoryArticleScreen(lesson: lesson))),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(children: [
              const Icon(Icons.menu_book_outlined, color: forest),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.2)),
                  const SizedBox(height: 4),
                  Text(lesson.summary, style: const TextStyle(color: moss, fontSize: 13, height: 1.25)),
                ]),
              ),
              const Icon(Icons.chevron_right, color: moss),
            ]),
          ),
        ),
      ),
    );
  }
}

class TheoryArticleScreen extends StatelessWidget {
  final TheoryLesson lesson;
  const TheoryArticleScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Теория')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(lesson.title, style: const TextStyle(fontFamily: floraDisplay, fontSize: 32, height: 1.05, color: ink)),
          const SizedBox(height: 8),
          Text(lesson.summary, style: const TextStyle(color: moss, fontSize: 16, height: 1.3)),
          const SizedBox(height: 16),
          for (final paragraph in lesson.paragraphs) ...[
            Text(paragraph, style: const TextStyle(fontSize: 16, height: 1.45, color: ink)),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
