import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';

class BetaMark extends StatelessWidget {
  final bool onDark;
  const BetaMark({super.key, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: onDark ? const Color(0xE6FFFCF7) : chipGreen,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          'БЕТА',
          style: TextStyle(color: forest, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
        ),
      ),
    );
  }
}
