import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../data/content_repository.dart';
import '../state/progress_controller.dart';
import 'key_screen.dart';
import 'quiz_screen.dart';
import 'report_screen.dart';
import 'survey_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.watch<ProgressController>();
    final total = context.read<ContentRepository>().species.length;

    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Флора Ленских столбов', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text('Определитель редких и исчезающих растений национального парка', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Icon(Icons.emoji_events, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.level.title, style: theme.textTheme.titleLarge),
                    Text('${p.points} баллов · определено ${p.identified.length} из $total'),
                  ]),
                ),
              ]),
            ),
          ),
          if (!p.surveyStages.contains('before'))
            Card(
              child: ListTile(
                leading: const Icon(Icons.assignment_outlined),
                title: const Text('Короткий опрос перед прогулкой'),
                subtitle: Text('2 минуты, +${Points.survey} баллов'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SurveyScreen(stage: SurveyStage.before)),
                ),
              ),
            ),
          const SizedBox(height: 8),
          _BigAction(
            icon: Icons.quiz_outlined,
            title: 'Определить растение',
            subtitle: 'Ответьте на несколько простых вопросов',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KeyScreen())),
          ),
          _BigAction(
            icon: Icons.photo_library_outlined,
            title: 'Все редкие виды',
            subtitle: 'Фотогалерея и фильтры по признакам',
            onTap: () => HomeShell.switchTab(context, 1),
          ),
          _BigAction(
            icon: Icons.add_location_alt_outlined,
            title: 'Сообщить о находке',
            subtitle: 'Координаты GPS и фото для научного отдела',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen())),
          ),
          _BigAction(
            icon: Icons.psychology_alt_outlined,
            title: 'Викторина',
            subtitle: 'Проверьте свои знания о растениях парка',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen())),
          ),
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.errorContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Любуйтесь, но не срывайте! Все растения в приложении редкие и охраняются законом. '
                'Приложение работает без интернета.',
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _BigAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _BigAction({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(radius: 26, child: Icon(icon, size: 28)),
          title: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 15)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
