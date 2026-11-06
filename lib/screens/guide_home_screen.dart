import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../state/session_controller.dart';
import '../theme/flora_theme.dart';
import '../widgets/beta_mark.dart';
import '../widgets/cover_panel.dart';
import 'key_screen.dart';
import 'theory_screen.dart';

class GuideHomeScreen extends StatelessWidget {
  const GuideHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionController>();
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20), children: [
          const _GuideBanner(),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Material(
              color: forestDark,
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KeyScreen())),
                child: const CoverPanel(
                  minHeight: 240,
                  background: Stack(fit: StackFit.expand, children: [
                    Image(
                      image: AssetImage('assets/images/white_flower.jpg'),
                      fit: BoxFit.cover,
                      alignment: Alignment(0.15, -0.1),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          stops: [0, 0.48, 0.86],
                          colors: [Color(0xF01B4636), Color(0xB31B4636), Color(0x331B4636)],
                        ),
                      ),
                    ),
                    Positioned(top: 16, right: 16, child: BetaMark(onDark: true)),
                  ]),
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0x33FFFFFF),
                      child: Icon(Icons.photo_camera_outlined, color: Colors.white),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Определить\nрастение по фото',
                      style: TextStyle(fontFamily: floraDisplay, color: Colors.white, fontSize: 26, height: 0.95),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Нейросеть в бете\nдля экскурсии',
                      style: TextStyle(color: Color(0xFFD5E0D4), fontSize: 15, height: 1.25),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: forest,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => session.selectTab(2),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0x33FFFFFF),
                    child: Icon(Icons.groups_outlined, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Создать экскурсию', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('Сформируйте маршрут и материалы', style: TextStyle(color: Color(0xFFD5E0D4), fontSize: 13)),
                    ]),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.02,
            children: [
              _GuideTile(
                image: 'assets/icons/guide_map.svg',
                title: 'Маршруты и\nточки интереса',
                subtitle: 'Готовые маршруты\nи ваши экскурсии',
                onTap: () => session.selectTab(3),
              ),
              _GuideTile(
                image: 'assets/icons/guide_plants.svg',
                title: 'Каталог\nрастений',
                subtitle: 'Описание, фото\nи интересные факты',
                onTap: () => session.selectTab(1),
              ),
              _GuideTile(
                image: 'assets/icons/guide_book.svg',
                title: 'Экскурсионные\nматериалы',
                subtitle: 'Теория и ваши\nматериалы',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TheoryScreen())),
              ),
              _GuideTile(
                image: 'assets/icons/guide_group.svg',
                title: 'Мои группы',
                subtitle: 'Участники и время\nна карточке экскурсии',
                onTap: () => session.selectTab(2),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}

class _GuideBanner extends StatelessWidget {
  const _GuideBanner();

  @override
  Widget build(BuildContext context) {
    return const CoverPanel(
      minHeight: 188,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 14),
      background: Stack(fit: StackFit.expand, children: [
        Image(
          image: AssetImage('assets/images/cliffs.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              stops: [0, 0.46, 0.82],
              colors: [Color(0xFFF3F0E6), Color(0xD9F3F0E6), Color(0x00F3F0E6)],
            ),
          ),
        ),
      ]),
      children: [
        Row(children: [
          Icon(Icons.spa, color: forest, size: 22),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Флора\nЛенских столбов',
              style: TextStyle(fontFamily: floraDisplay, fontSize: 20, height: 1.02, color: ink),
            ),
          ),
        ]),
        SizedBox(height: 10),
        Row(children: [
          Icon(Icons.explore_outlined, color: forest, size: 18),
          SizedBox(width: 8),
          Text('Гид', style: TextStyle(fontFamily: floraDisplay, fontSize: 22, color: ink)),
        ]),
        SizedBox(height: 6),
        Text(
          'Создавайте маршруты,\nделитесь знаниями\nи проводите экскурсии',
          style: TextStyle(fontSize: 13, height: 1.25, color: moss),
        ),
        SizedBox(height: 8),
        SizedBox(width: 42, height: 2, child: ColoredBox(color: Color(0xFFB08968))),
      ],
    );
  }
}

class _GuideTile extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _GuideTile({required this.image, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: paper,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Align(alignment: Alignment.centerRight, child: Icon(Icons.chevron_right, size: 18, color: moss)),
            Expanded(
              child: Row(children: [
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: chipGreen, borderRadius: BorderRadius.circular(18)),
                  child: SvgPicture.asset(image),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.1, color: ink)),
                    const SizedBox(height: 4),
                    Text(subtitle, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.15, color: moss)),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
