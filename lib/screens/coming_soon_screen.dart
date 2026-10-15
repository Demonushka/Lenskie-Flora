import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/session_controller.dart';
import '../theme/flora_theme.dart';
import '../widgets/park_banner.dart';

class ComingSoonScreen extends StatelessWidget {
  final String title;
  const ComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const ParkBanner(),
            const SizedBox(height: 28),
            Text(title, style: const TextStyle(fontFamily: floraDisplay, fontSize: 36)),
            const SizedBox(height: 8),
            const Text(
              'Этот режим есть в макете отдельным профилем. Сейчас собрана клиентская база туриста.',
              style: TextStyle(fontSize: 16, height: 1.35, color: moss),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => context.read<SessionController>().clearRole(),
              child: const Text('Выбрать другую роль'),
            ),
          ]),
        ),
      ),
    );
  }
}
