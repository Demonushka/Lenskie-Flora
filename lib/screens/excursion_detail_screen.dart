import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../data/theory_content.dart';
import '../models/excursion.dart';
import '../models/species.dart';
import '../state/excursion_controller.dart';
import '../theme/flora_theme.dart';
import 'key_screen.dart';

class ExcursionDetailScreen extends StatefulWidget {
  final String excursionId;
  const ExcursionDetailScreen({super.key, required this.excursionId});

  @override
  State<ExcursionDetailScreen> createState() => _ExcursionDetailScreenState();
}

class _ExcursionDetailScreenState extends State<ExcursionDetailScreen> {
  late final TextEditingController _title;
  late final TextEditingController _meeting;
  late final TextEditingController _story;
  late final TextEditingController _participant;
  ExcursionController? _tours;
  int _duration = 90;
  String _departure = '10:00';
  List<String> _participants = [];
  List<ExcursionStop> _stops = [];
  bool _ready = false;
  bool _deleted = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _meeting = TextEditingController();
    _story = TextEditingController();
    _participant = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tours ??= context.read<ExcursionController>();
    if (_ready) return;
    final tour = _tours!.byId(widget.excursionId);
    if (tour == null) return;
    _title.text = tour.title;
    _meeting.text = tour.meetingPoint;
    _story.text = tour.story;
    _duration = tour.durationMinutes;
    _departure = tour.departure;
    _participants = [...tour.participants];
    _stops = [...tour.stops];
    _ready = true;
  }

  @override
  void dispose() {
    _persist();
    _title.dispose();
    _meeting.dispose();
    _story.dispose();
    _participant.dispose();
    super.dispose();
  }

  void _persist() {
    if (!_ready || _deleted) return;
    final current = _tours?.byId(widget.excursionId);
    if (current == null) return;
    final title = _title.text.trim();
    _tours!.update(current.copyWith(
      title: title.isEmpty ? current.title : title,
      meetingPoint: _meeting.text.trim(),
      story: _story.text.trim(),
      durationMinutes: _duration,
      departure: _departure,
      participants: _participants,
      stops: _stops,
    ));
  }

  void _save() => _persist();

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: Text('Экскурсия не найдена')));
    }
    final repo = context.read<ContentRepository>();
    final lessons = theoryFor('guide');
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Экскурсия'),
        actions: [
          IconButton(
            tooltip: 'Удалить',
            onPressed: () async {
              _deleted = true;
              await _tours!.remove(widget.excursionId);
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _field(_title, 'Название', 'Как назвать выход'),
          const SizedBox(height: 12),
          const Text('Длительность', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final minutes in [60, 90, 120, 180])
              ChoiceChip(
                label: Text('$minutes мин'),
                selected: _duration == minutes,
                onSelected: (_) => setState(() {
                  _duration = minutes;
                  _save();
                }),
              ),
          ]),
          const SizedBox(height: 12),
          _field(_meeting, 'Место сбора', 'Причал, смотровая, стоянка'),
          const SizedBox(height: 12),
          _field(_story, 'Текст для начала', 'О чём сказать группе', lines: 4),
          const SizedBox(height: 16),
          const Text('Группа', style: TextStyle(fontFamily: floraDisplay, fontSize: 28, color: ink)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showTimePicker(context: context, initialTime: _time(_departure));
              if (picked == null) return;
              setState(() {
                _departure = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                _save();
              });
            },
            icon: const Icon(Icons.schedule),
            label: Text('Выход в $_departure'),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _field(_participant, 'Участник', 'Имя')),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Добавить',
              onPressed: _addParticipant,
              icon: const Icon(Icons.add),
            ),
          ]),
          if (_participants.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final name in _participants)
                InputChip(
                  label: Text(name),
                  onDeleted: () => setState(() {
                    _participants = [..._participants]..remove(name);
                    _save();
                  }),
                ),
            ]),
          ],
          const SizedBox(height: 18),
          const Text('Остановки', style: TextStyle(fontFamily: floraDisplay, fontSize: 28, color: ink)),
          const SizedBox(height: 4),
          const Text(
            'Зоны со схемы парка. Точные точки редких растений сюда не ставятся.',
            style: TextStyle(color: moss, height: 1.3),
          ),
          const SizedBox(height: 10),
          for (final stop in _stops) ...[
            _StopCard(
              stop: stop,
              zoneName: _zoneName(repo, stop.zoneId),
              zoneNote: _zoneNote(repo, stop.zoneId),
              species: [for (final id in stop.speciesIds) if (repo.byId(id) != null) repo.byId(id)!],
              lesson: _lesson(lessons, stop.theoryId),
              onSpecies: () => _pickSpecies(repo, stop),
              onTheory: () => _pickTheory(lessons, stop),
              onDone: (done) => _replace(stop.copyWith(done: done)),
              onRemove: () => setState(() {
                _stops = [..._stops]..remove(stop);
                _save();
              }),
              onIdentify: () {
                _save();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const KeyScreen()));
              },
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: () => _addStop(repo),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Добавить остановку'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, String hint, {int lines = 1}) {
    return TextField(
      controller: controller,
      minLines: lines,
      maxLines: lines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: paper,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      ),
      onChanged: (_) => _persist(),
    );
  }

  void _addParticipant() {
    final name = _participant.text.trim();
    if (name.isEmpty || _participants.contains(name)) return;
    setState(() {
      _participants = [..._participants, name];
      _participant.clear();
      _save();
    });
  }

  Future<void> _addStop(ContentRepository repo) async {
    final used = _stops.map((stop) => stop.zoneId).toSet();
    final zones = repo.map.zones.where((zone) => !used.contains(zone.id)).toList();
    if (zones.isEmpty) return;
    final id = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: Text('Зона на схеме')),
          for (final zone in zones)
            ListTile(
              title: Text(zone.name),
              subtitle: Text(zone.description),
              onTap: () => Navigator.pop(context, zone.id),
            ),
        ],
      ),
    );
    if (id == null) return;
    setState(() {
      _stops = [..._stops, ExcursionStop(zoneId: id)];
      _save();
    });
  }

  Future<void> _pickSpecies(ContentRepository repo, ExcursionStop stop) async {
    final selected = {...stop.speciesIds};
    final inZone = repo.inZone(stop.zoneId);
    final rest = repo.species.where((species) => !species.parkZones.contains(stop.zoneId)).toList();
    final picked = await showModalBottomSheet<Set<String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          Widget tile(Species species) {
            final on = selected.contains(species.id);
            return CheckboxListTile(
              value: on,
              title: Text(species.nameRu),
              subtitle: Text(species.nameLat, style: const TextStyle(fontStyle: FontStyle.italic)),
              onChanged: (value) {
                setSheet(() {
                  if (value == true && selected.length < 3) selected.add(species.id);
                  if (value != true) selected.remove(species.id);
                });
              },
            );
          }

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            builder: (_, controller) => Column(children: [
              const ListTile(
                title: Text('До трёх видов на остановку'),
                subtitle: Text('Сначала те, что отмечены в этой зоне'),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    if (inZone.isEmpty)
                      const ListTile(title: Text('В этой зоне на схеме нет отдельного вида. Можно выбрать любой из каталога.')),
                    for (final species in inZone) tile(species),
                    if (rest.isNotEmpty && inZone.isNotEmpty) const ListTile(title: Text('Остальной каталог')),
                    for (final species in rest) tile(species),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(onPressed: () => Navigator.pop(context, selected), child: const Text('Готово')),
              ),
            ]),
          );
        },
      ),
    );
    if (picked == null) return;
    _replace(stop.copyWith(speciesIds: picked.take(3).toList()));
  }

  Future<void> _pickTheory(List<TheoryLesson> lessons, ExcursionStop stop) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(title: const Text('Без темы'), onTap: () => Navigator.pop(context, '')),
          for (final lesson in lessons)
            ListTile(
              title: Text(lesson.title),
              subtitle: Text(lesson.summary),
              onTap: () => Navigator.pop(context, lesson.id),
            ),
        ],
      ),
    );
    if (id == null) return;
    _replace(id.isEmpty ? stop.copyWith(clearTheory: true) : stop.copyWith(theoryId: id));
  }

  void _replace(ExcursionStop stop) {
    setState(() {
      _stops = [for (final item in _stops) item.zoneId == stop.zoneId ? stop : item];
      _save();
    });
  }

  String _zoneName(ContentRepository repo, String id) {
    for (final zone in repo.map.zones) {
      if (zone.id == id) return zone.name;
    }
    return id;
  }

  String _zoneNote(ContentRepository repo, String id) {
    for (final zone in repo.map.zones) {
      if (zone.id == id) return zone.description;
    }
    return '';
  }

  TheoryLesson? _lesson(List<TheoryLesson> lessons, String? id) {
    for (final lesson in lessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  TimeOfDay _time(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 10, minute: 0);
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? 10, minute: int.tryParse(parts[1]) ?? 0);
  }
}

class _StopCard extends StatelessWidget {
  final ExcursionStop stop;
  final String zoneName;
  final String zoneNote;
  final List<Species> species;
  final TheoryLesson? lesson;
  final VoidCallback onSpecies;
  final VoidCallback onTheory;
  final ValueChanged<bool> onDone;
  final VoidCallback onRemove;
  final VoidCallback onIdentify;

  const _StopCard({
    required this.stop,
    required this.zoneName,
    required this.zoneNote,
    required this.species,
    required this.lesson,
    required this.onSpecies,
    required this.onTheory,
    required this.onDone,
    required this.onRemove,
    required this.onIdentify,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(zoneName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
          IconButton(tooltip: 'Убрать', onPressed: onRemove, icon: const Icon(Icons.close, size: 18, color: moss)),
        ]),
        if (zoneNote.isNotEmpty) Text(zoneNote, style: const TextStyle(color: moss, height: 1.3)),
        const SizedBox(height: 8),
        Text(
          species.isEmpty ? 'Виды не выбраны' : species.map((item) => item.nameRu).join(', '),
          style: const TextStyle(height: 1.3),
        ),
        const SizedBox(height: 4),
        Text(lesson == null ? 'Тема для рассказа не выбрана' : lesson!.title, style: const TextStyle(color: moss)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton(onPressed: onSpecies, child: const Text('Виды')),
          OutlinedButton(onPressed: onTheory, child: const Text('Тема')),
        ]),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Прошли'),
          value: stop.done,
          onChanged: onDone,
        ),
        FilledButton.icon(onPressed: onIdentify, icon: const Icon(Icons.search), label: const Text('Определить')),
      ]),
    );
  }
}
