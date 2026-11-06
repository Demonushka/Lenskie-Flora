import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../state/progress_controller.dart';
import '../state/session_controller.dart';
import '../theme/flora_theme.dart';
import '../widgets/beta_mark.dart';
import '../widgets/cover_panel.dart';
import '../widgets/park_banner.dart';
import 'collection_screen.dart';
import 'progress_screen.dart';
import 'quiz_screen.dart';
import 'theory_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final total = context.read<ContentRepository>().species.length;
    final found = progress.seen.length;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20), children: [
          const ParkBanner(),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Material(
              color: forestDark,
              child: InkWell(
                onTap: () => context.read<SessionController>().openIdentify(),
                child: const CoverPanel(
                  minHeight: 272,
                  padding: EdgeInsets.all(22),
                  background: Stack(fit: StackFit.expand, children: [
                    Image(
                      image: AssetImage('assets/images/white_flower.jpg'),
                      fit: BoxFit.cover,
                      alignment: Alignment(0.15, -0.1),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          stops: [0, 0.46, 0.82],
                          colors: [Color(0xF01B4636), Color(0xB31B4636), Color(0x331B4636)],
                        ),
                      ),
                    ),
                    const Positioned(top: 16, right: 16, child: BetaMark(onDark: true)),
                  ]),
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0x33FFFFFF),
                      child: Icon(Icons.photo_camera_outlined, color: Colors.white),
                    ),
                    SizedBox(height: 18),
                    Text(
                      'ОПРЕДЕЛИТЬ\nРАСТЕНИЕ ПО ФОТО',
                      style: TextStyle(fontFamily: floraDisplay, color: Colors.white, fontSize: 24, height: 0.95),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Нейросеть в бете смотрит снимок.\nЕсли не знает — вопросы',
                      style: TextStyle(color: Color(0xFFD5E0D4), fontSize: 15, height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: paper,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectionScreen())),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Text('МОЯ КОЛЛЕКЦИЯ', style: TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.w700, color: moss)),
                    Spacer(),
                    Icon(Icons.chevron_right, color: moss),
                  ]),
                  const SizedBox(height: 8),
                  Text('$found из $total видов', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: total == 0 ? 0 : (found / total).clamp(0.0, 1.0).toDouble(),
                      backgroundColor: const Color(0xFFE6EFE3),
                      color: forest,
                    ),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.92,
            children: [
              _MenuCard(
                icon: Icons.menu_book_outlined,
                title: 'КАТАЛОГ\nРАСТЕНИЙ',
                subtitle: 'Изучайте уникальную флору парка',
                onTap: () => context.read<SessionController>().selectTab(1),
              ),
              _MenuCard(
                icon: Icons.map_outlined,
                title: 'КАРТА\nПАРКА',
                subtitle: 'Находите растения и их естественную среду',
                onTap: () => context.read<SessionController>().selectTab(3),
              ),
              _MenuCard(
                icon: Icons.emoji_events_outlined,
                title: 'ДОСТИЖЕНИЯ',
                subtitle: 'Открывайте новые виды и получайте награды',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen())),
              ),
              _MenuCard(
                icon: Icons.lightbulb_outline,
                title: 'ВИКТОРИНА',
                subtitle: 'Проверьте знания и узнавайте новое о растениях',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen())),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: paper,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TheoryScreen())),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(children: [
                  Icon(Icons.menu_book_outlined, color: forest),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Теоретическая база', style: TextStyle(fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text('Почему растения редкие и как на них смотреть', style: TextStyle(color: moss, fontSize: 13)),
                    ]),
                  ),
                  Icon(Icons.chevron_right, color: moss),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: paper,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Spacer(),
              const Icon(Icons.chevron_right, size: 18, color: moss),
            ]),
            Icon(icon, color: forest, size: 32),
            const Spacer(),
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, height: 1.1, letterSpacing: 0.4)),
            const SizedBox(height: 4),
            Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: moss, height: 1.2)),
          ]),
        ),
      ),
    );
  }
}
