import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> confirmAppExit(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Выйти из приложения?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Остаться')),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти')),
      ],
    ),
  );
  if (leave == true && context.mounted) {
    await SystemNavigator.pop();
  }
}
