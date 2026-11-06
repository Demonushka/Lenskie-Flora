import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../models/excursion.dart';
import '../state/excursion_controller.dart';
import '../theme/flora_theme.dart';
import 'excursion_detail_screen.dart';

class GuideExcursionsScreen extends StatefulWidget {
  const GuideExcursionsScreen({super.key});

  @override
  State<GuideExcursionsScreen> createState() => _GuideExcursionsScreenState();
}

class _GuideExcursionsScreenState extends State<GuideExcursionsScreen> {
  final _name = TextEditingController();
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final title = _name.text.trim();
    if (title.isEmpty) {
      setState(() => _nameError = 'Требуется название экскурсии');
      return;
    }
    setState(() => _nameError = null);
    final tours = context.read<ExcursionController>();
    final tour = await tours.create(title);
    if (!mounted) return;
    _name.clear();
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ExcursionDetailScreen(excursionId: tour.id)));
  }

  @override
  Widget build(BuildContext context) {
    final tours = context.watch<ExcursionController>().items;
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), children: [
          const Text('Экскурсии', style: TextStyle(fontFamily: floraDisplay, fontSize: 32, color: ink)),
          const SizedBox(height: 6),
          const Text('Остановки по зонам парка, виды и группа', style: TextStyle(color: moss, fontSize: 15)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Название экскурсии',
              errorText: _nameError,
              filled: true,
              fillColor: paper,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            ),
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            onSubmitted: (_) => _add(),
          ),
          const SizedBox(height: 10),
          FilledButton(onPressed: _add, child: const Text('Создать экскурсию')),
          const SizedBox(height: 18),
          if (tours.isEmpty)
            const Text('Пока нет своих экскурсий.', style: TextStyle(color: moss))
          else
            for (final tour in tours)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: paper,
                  borderRadius: BorderRadius.circular(20),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    leading: Container(
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: chipGreen, borderRadius: BorderRadius.circular(14)),
                      child: SvgPicture.asset('assets/icons/guide_map.svg'),
                    ),
                    title: Text(tour.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(_subtitle(tour)),
                    trailing: const Icon(Icons.chevron_right, color: moss),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ExcursionDetailScreen(excursionId: tour.id)),
                    ),
                  ),
                ),
              ),
        ]),
      ),
    );
  }

  String _subtitle(Excursion tour) {
    final stops = tour.stops.isEmpty ? 'остановки не выбраны' : '${tour.doneCount} из ${tour.stops.length} пройдено';
    final people = tour.participants.isEmpty ? 'группа не указана' : '${tour.participants.length} участн.';
    return '$stops · выход ${tour.departure} · $people';
  }
}
