import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/theory_content.dart';
import '../models/excursion.dart';
import '../state/excursion_controller.dart';
import '../state/session_controller.dart';
import '../theme/flora_theme.dart';
import 'guide_material_screen.dart';

class TheoryScreen extends StatelessWidget {
  const TheoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<SessionController>().role;
    final lessons = theoryFor(role);
    final staff = role == 'guide' || role == 'inspector';
    final guide = role == 'guide';
    final materials = guide ? _guideMaterials(context.watch<ExcursionController>().items) : const <_GuideMaterialRef>[];
    final intro = switch (role) {
      'guide' => 'Основа для посетителя, готовые темы и ваши материалы для конкретной экскурсии.',
      'inspector' => 'Основа для посетителя и правила полевого учёта.',
      _ => 'Короткая база: почему растения редкие и как на них смотреть. Карточки видов остаются прежними.',
    };

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: Text(guide ? 'Экскурсионные материалы' : 'Теория')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(intro, style: const TextStyle(color: moss, height: 1.35)),
          if (guide) ...[
            const SizedBox(height: 16),
            const _Heading('Авторские'),
            const Text(
              'Текст или файл для экскурсии. Остаётся на этом телефоне.',
              style: TextStyle(color: moss, height: 1.35),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () => addGuideMaterial(context),
              icon: const Icon(Icons.upload_file),
              label: const Text('Загрузить материал'),
            ),
            const SizedBox(height: 12),
            if (materials.isEmpty)
              const Text('Своих материалов пока нет.', style: TextStyle(color: moss))
            else
              for (final item in materials) _MaterialTile(item: item),
          ],
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

class _GuideMaterialRef {
  final String excursionId;
  final String excursionTitle;
  final ExcursionMaterial material;

  const _GuideMaterialRef(this.excursionId, this.excursionTitle, this.material);
}

List<_GuideMaterialRef> _guideMaterials(List<Excursion> tours) => [
      for (final tour in tours)
        for (final material in tour.materials) _GuideMaterialRef(tour.id, tour.title, material),
    ];

class _MaterialTile extends StatelessWidget {
  final _GuideMaterialRef item;
  const _MaterialTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final file = item.material.fileName;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: paper,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GuideMaterialArticle(
                excursionId: item.excursionId,
                excursionTitle: item.excursionTitle,
                material: item.material,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
            child: Row(children: [
              const Icon(Icons.note_alt_outlined, color: forest),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.material.title, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.2)),
                  const SizedBox(height: 4),
                  Text(
                    file == null ? item.excursionTitle : '${item.excursionTitle} · $file',
                    style: const TextStyle(color: moss, fontSize: 13, height: 1.25),
                  ),
                ]),
              ),
              IconButton(
                tooltip: 'Удалить материал',
                onPressed: () => confirmRemoveMaterial(context, item.excursionId, item.material.id),
                icon: const Icon(Icons.delete_outline, color: moss),
              ),
            ]),
          ),
        ),
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
