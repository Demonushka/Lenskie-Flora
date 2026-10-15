import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/staff_gate.dart';
import '../state/session_controller.dart';
import '../theme/flora_theme.dart';
import '../widgets/park_banner.dart';

class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  String _role = 'tourist';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
          const ParkBanner(),
          const SizedBox(height: 28),
          const Text('Кто вы?', style: TextStyle(fontFamily: floraDisplay, fontSize: 36, color: ink)),
          const SizedBox(height: 4),
          const Text('Выберите режим использования', style: TextStyle(fontSize: 16, color: moss)),
          const SizedBox(height: 18),
          _RoleCard(
            selected: _role == 'tourist',
            icon: Icons.hiking,
            title: 'Турист',
            text: 'Определяйте растения, собирайте коллекцию и проходите викторины',
            onTap: () => setState(() => _role = 'tourist'),
          ),
          _RoleCard(
            selected: _role == 'guide',
            icon: Icons.tour,
            title: 'Гид',
            text: 'Используйте карточки видов и материалы для экскурсий',
            onTap: () => setState(() => _role = 'guide'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.read<SessionController>().chooseRole(_role),
            child: const Text('Продолжить  ›'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _openStaff(context),
            child: const Text('Служебный вход'),
          ),
        ]),
      ),
    );
  }

  Future<void> _openStaff(BuildContext context) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => const _StaffCodeDialog(),
    );
    if (accepted == true && context.mounted) {
      await context.read<SessionController>().chooseRole('inspector');
    }
  }
}

class _StaffCodeDialog extends StatefulWidget {
  const _StaffCodeDialog();

  @override
  State<_StaffCodeDialog> createState() => _StaffCodeDialogState();
}

class _StaffCodeDialogState extends State<_StaffCodeDialog> {
  final _code = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    if (inspectorCodeMatches(_code.text)) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _wrong = true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Служебный вход'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Код выдаёт парк. Он открывает режим инспектора на этом телефоне.'),
        const SizedBox(height: 12),
        TextField(
          controller: _code,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 8,
          decoration: InputDecoration(
            labelText: 'Код',
            errorText: _wrong ? 'Неверный код' : null,
          ),
          onChanged: (_) {
            if (_wrong) setState(() => _wrong = false);
          },
          onSubmitted: (_) => _submit(),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
        FilledButton(onPressed: _submit, child: const Text('Войти')),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String text;
  final VoidCallback onTap;

  const _RoleCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: paper,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: selected ? forest : Colors.transparent, width: 1.4),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFE7F0E2),
                child: Icon(icon, color: forest),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(text, style: const TextStyle(fontSize: 14, height: 1.3, color: moss)),
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
