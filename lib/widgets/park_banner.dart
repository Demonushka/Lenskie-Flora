import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import 'cover_panel.dart';

class ParkBanner extends StatelessWidget {
  const ParkBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return CoverPanel(
      minHeight: 220,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      background: const Stack(fit: StackFit.expand, children: [
        Image(
          image: AssetImage('assets/images/cliffs.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              stops: [0, 0.42, 0.78],
              colors: [Color(0xF2F3F0E6), Color(0x88F3F0E6), Color(0x00F3F0E6)],
            ),
          ),
        ),
      ]),
      children: [
        const Row(children: [
          Icon(Icons.spa, color: forest, size: 22),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'ФЛОРА\nЛЕНСКИХ СТОЛБОВ',
              style: TextStyle(fontFamily: floraDisplay, fontSize: 18, height: 1.05, color: ink),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        const Text(
          'Определитель редких растений парка',
          style: TextStyle(fontSize: 12, color: moss),
        ),
        const SizedBox(height: 8),
        Text(
          'Уникальная природа\nрядом с вами',
          style: TextStyle(
            fontSize: 16,
            height: 1.15,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            color: forest.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
