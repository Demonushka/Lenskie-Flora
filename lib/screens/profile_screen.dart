import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../data/info_content.dart';
import '../models/labels.dart';
import '../state/observation_controller.dart';
import '../state/progress_controller.dart';
import '../state/session_controller.dart';
import '../theme/flora_theme.dart';
import '../widgets/park_banner.dart';
import 'inspector_home_screen.dart';
import 'more_screen.dart';
import 'report_screen.dart';
import 'survey_screen.dart';
import 'theory_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final progress = context.watch<ProgressController>();
    final repo = context.read<ContentRepository>();
    final activity = progress.seen.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final days = progress.seen.values.map((v) => v.length >= 10 ? v.substring(0, 10) : v).toSet().length;
    final guide = session.role == 'guide';
    final inspector = session.role == 'inspector';

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), children: [
          const ParkBanner(),
          const SizedBox(height: 22),
          const Text('МОЙ ПРОФИЛЬ', style: TextStyle(letterSpacing: 1.4, fontWeight: FontWeight.w800, color: moss)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(24)),
            child: Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFE7F0E2),
                child: Icon(inspector ? Icons.shield_outlined : guide ? Icons.explore_outlined : Icons.hiking, color: forest),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(session.displayName, style: const TextStyle(fontFamily: floraDisplay, fontSize: 26)),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: chipGreen, borderRadius: BorderRadius.circular(8)),
                    child: Text(inspector ? 'Инспектор' : guide ? 'Гид' : 'Турист', style: const TextStyle(fontSize: 12, color: forest, fontWeight: FontWeight.w600)),
                  ),
                  Text(
                    inspector
                        ? 'Фиксируйте наблюдения и состояние территории'
                        : guide
                            ? 'Проводите экскурсии по Ленским столбам'
                            : 'Исследователь природы ленских столбов',
                    style: const TextStyle(fontSize: 13, color: moss),
                  ),
                ]),
              ),
              IconButton(
                tooltip: 'Изменить имя',
                onPressed: () => _rename(context, session),
                icon: const Icon(Icons.edit_outlined, color: moss),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          if (inspector)
            const _InspectorSummary()
          else ...[
            Row(children: [
              Expanded(child: _Stat(value: '${progress.seen.length}', label: 'растений')),
              const SizedBox(width: 12),
              Expanded(child: _Stat(value: '$days', label: 'маршрута')),
            ]),
            const SizedBox(height: 22),
            const Text('Недавняя активность', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (activity.isEmpty)
              const Text('Коллекция пока пуста. Отметьте растение в карточке вида.', style: TextStyle(color: moss))
            else
              for (final item in activity.take(5))
                if (repo.byId(item.key) != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFFE7F0E2),
                          child: Icon(Icons.spa, size: 16, color: forest),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(repo.byId(item.key)!.nameRu, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const Text('добавлено в коллекцию', style: TextStyle(fontSize: 13, color: moss)),
                          ]),
                        ),
                        Text(_day(item.value), style: const TextStyle(fontSize: 12, color: moss)),
                      ]),
                    ),
                  ),
          ],
          const SizedBox(height: 8),
          _Link(title: 'Теоретическая база', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TheoryScreen()))),
          _Link(title: 'Правила парка', onTap: () => _openInfo(context, infoPages[0])),
          _Link(title: 'Контакты парка', onTap: () => _openInfo(context, infoPages[2])),
          _Link(title: 'О проекте', onTap: () => _openInfo(context, infoPages[3])),
          if (!inspector) ...[
            _Link(title: 'Сообщить о находке', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()))),
            _Link(
              title: 'Опрос',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SurveyScreen(stage: SurveyStage.after))),
            ),
          ],
          const SizedBox(height: 8),
          TextButton(onPressed: () => session.clearRole(), child: const Text('Сменить режим')),
        ]),
      ),
    );
  }

  Future<void> _rename(BuildContext context, SessionController session) async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _RenameDialog(initialName: session.displayName),
    );
    if (name != null) await session.rename(name);
  }

  void _openInfo(BuildContext context, InfoPage page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => InfoScreen(page: page)));
  }

  static String _day(String iso) {
    final date = DateTime.tryParse(iso)?.toLocal();
    if (date == null) return '';
    return '${date.day} ${monthNames[date.month - 1]}';
  }
}

class _RenameDialog extends StatefulWidget {
  final String initialName;
  const _RenameDialog({required this.initialName});

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Как к вам обращаться?'),
      content: TextField(controller: _controller, autofocus: true, textCapitalization: TextCapitalization.words),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        TextButton(onPressed: () => Navigator.pop(context, _controller.text), child: const Text('Сохранить')),
      ],
    );
  }
}

class _InspectorSummary extends StatelessWidget {
  const _InspectorSummary();

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<ObservationController>();
    final repo = context.read<ContentRepository>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: _Stat(value: '${notes.plants.length}', label: 'наблюдений')),
        const SizedBox(width: 12),
        Expanded(child: _Stat(value: '${notes.reports.length}', label: 'отчётов')),
      ]),
      const SizedBox(height: 22),
      const Text('Недавние записи', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      if (notes.notes.isEmpty)
        const Text('Записей пока нет. Наблюдение — это растение, отчёт — след на территории.', style: TextStyle(color: moss))
      else
        for (final note in notes.notes.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: paper,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InspectorCaptureScreen(note: note))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFE7F0E2),
                      child: Icon(note.isPlant ? Icons.spa : Icons.report_outlined, size: 16, color: forest),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          note.isPlant ? (repo.byId(note.speciesId ?? '')?.nameRu ?? 'Наблюдение') : note.kindLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(note.text.isEmpty ? (note.isPlant ? 'Растение' : 'Отчёт') : note.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: moss)),
                      ]),
                    ),
                    const Icon(Icons.edit_outlined, size: 18, color: moss),
                  ]),
                ),
              ),
            ),
          ),
    ]);
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(22)),
      child: Column(children: [
        Text(value, style: const TextStyle(fontFamily: floraDisplay, fontSize: 32, color: forest)),
        Text(label, style: const TextStyle(color: moss)),
      ]),
    );
  }
}

class _Link extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _Link({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: paper,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right, color: moss),
          onTap: onTap,
        ),
      ),
    );
  }
}
