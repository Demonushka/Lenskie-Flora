import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/session_controller.dart';
import '../theme/flora_theme.dart';

class FloraNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const FloraNavBar({super.key, required this.index, required this.onTap});

  static const _tourist = [
    (Icons.home_outlined, Icons.home, 'Главная'),
    (Icons.spa_outlined, Icons.spa, 'Растения'),
    (Icons.energy_savings_leaf_outlined, Icons.energy_savings_leaf, 'Определить'),
    (Icons.place_outlined, Icons.place, 'Карта'),
    (Icons.person_outline, Icons.person, 'Профиль'),
  ];

  static const _inspector = [
    (Icons.home_outlined, Icons.home, 'Главная'),
    (Icons.biotech_outlined, Icons.biotech, 'Наблюдения'),
    (Icons.place_outlined, Icons.place, 'Карта'),
    (Icons.description_outlined, Icons.description, 'Отчёты'),
    (Icons.person_outline, Icons.person, 'Профиль'),
  ];

  static const _guide = [
    (Icons.home_outlined, Icons.home, 'Главная'),
    (Icons.spa_outlined, Icons.spa, 'Растения'),
    (Icons.menu_book_outlined, Icons.menu_book, 'Экскурсии'),
    (Icons.place_outlined, Icons.place, 'Карта'),
    (Icons.person_outline, Icons.person, 'Профиль'),
  ];

  @override
  Widget build(BuildContext context) {
    final role = context.watch<SessionController>().role;
    final items = switch (role) {
      'guide' => _guide,
      'inspector' => _inspector,
      _ => _tourist,
    };
    return Material(
      color: paper,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 42,
                        height: 32,
                        decoration: BoxDecoration(
                          color: index == i ? forest : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          index == i ? items[i].$2 : items[i].$1,
                          size: 22,
                          color: index == i ? Colors.white : const Color(0xFF8D8A82),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].$3,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: index == i ? FontWeight.w600 : FontWeight.w500,
                          color: index == i ? forest : const Color(0xFF8D8A82),
                        ),
                      ),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
