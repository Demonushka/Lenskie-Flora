import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../logic/park_proximity.dart';
import '../models/labels.dart';
import '../services/location_service.dart';
import '../state/observation_controller.dart';
import '../state/session_controller.dart';
import '../theme/flora_theme.dart';
import 'catalog_screen.dart';
import 'theory_screen.dart';

class InspectorHomeScreen extends StatelessWidget {
  const InspectorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionController>();
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20), children: [
          const _InspectorBanner(),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Material(
              color: forestDark,
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InspectorCaptureScreen())),
                child: const SizedBox(
                  height: 230,
                  child: Stack(fit: StackFit.expand, children: [
                    Image(image: AssetImage('assets/images/white_flower.jpg'), fit: BoxFit.cover, alignment: Alignment(0.15, -0.1)),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          stops: [0, 0.48, 0.86],
                          colors: [Color(0xF01B4636), Color(0xB31B4636), Color(0x331B4636)],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Color(0x33FFFFFF),
                          child: Icon(Icons.photo_camera_outlined, color: Colors.white),
                        ),
                        Spacer(),
                        Text('Зафиксировать\nнаблюдение', style: TextStyle(fontFamily: floraDisplay, color: Colors.white, fontSize: 28, height: 0.95)),
                        SizedBox(height: 8),
                        Text('Добавьте растение, состояние\nтерритории или проблему', style: TextStyle(color: Color(0xFFD5E0D4), fontSize: 15, height: 1.25)),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: paper,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => session.selectTab(3),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Row(children: [
                  CircleAvatar(radius: 22, backgroundColor: chipGreen, child: Icon(Icons.description_outlined, color: forest)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Мои отчёты', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ink)),
                      SizedBox(height: 2),
                      Text('Состояние территории и проблемы', style: TextStyle(color: moss, fontSize: 13)),
                    ]),
                  ),
                  Icon(Icons.chevron_right, color: moss),
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
              _InspectorTile(
                icon: 'assets/icons/guide_map.svg',
                title: 'Карта\nнаблюдений',
                subtitle: 'Все зафиксированные\nточки на карте',
                onTap: () => session.selectTab(2),
              ),
              _InspectorTile(
                icon: 'assets/icons/guide_plants.svg',
                title: 'Каталог\nрастений',
                subtitle: 'Описание, фото\nи статус вида',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogScreen())),
              ),
              _InspectorTile(
                icon: 'assets/icons/inspector_chart.svg',
                title: 'Статистика\nтерритории',
                subtitle: 'Виды, редкие растения,\nизменения',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InspectorStatsScreen())),
              ),
              _InspectorTile(
                icon: 'assets/icons/inspector_alert.svg',
                title: 'Сообщить\nо проблеме',
                subtitle: 'Нелегальная вырубка,\nмусор, нарушение',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InspectorCaptureScreen(kind: 'problem')),
                ),
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
                      Text('Теоретическая база', style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
                      SizedBox(height: 2),
                      Text('Основа и правила полевого учёта', style: TextStyle(color: moss, fontSize: 13)),
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

const _phases = {
  'vegetation': 'Вегетация',
  'budding': 'Бутоны',
  'flowering': 'Цветение',
  'fruiting': 'Плоды',
};

const _counts = {
  '1': '1 растение',
  '2-10': '2–10',
  '11-50': '11–50',
  '50+': 'Больше 50',
};

class InspectorNotesScreen extends StatelessWidget {
  final bool reports;
  const InspectorNotesScreen({super.key, this.reports = false});

  @override
  Widget build(BuildContext context) {
    final all = context.watch<ObservationController>();
    final notes = reports ? all.reports : all.plants;
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), children: [
          Text(reports ? 'Отчёты' : 'Наблюдения', style: const TextStyle(fontFamily: floraDisplay, fontSize: 32, color: ink)),
          const SizedBox(height: 6),
          Text(
            reports ? 'Состояние территории и проблемы. Вид растения не нужен.' : 'Учёт растения: вид, состояние и число. Каталог от этого не меняется.',
            style: const TextStyle(color: moss, height: 1.3),
          ),
          const SizedBox(height: 12),
          if (reports) ...[
            _KindButton('Состояние территории', 'territory'),
            _KindButton('Проблема', 'problem'),
          ] else
            _KindButton('Записать растение', 'plant'),
          const SizedBox(height: 12),
          if (notes.isEmpty)
            Text(
              reports ? 'Отчётов пока нет. Опишите след: сбор, мусор, колею.' : 'Наблюдений пока нет. Запишите растение на месте.',
              style: const TextStyle(color: moss),
            )
          else
            for (final note in notes) _NoteCard(note),
        ]),
      ),
    );
  }
}

class _KindButton extends StatelessWidget {
  final String label;
  final String kind;
  const _KindButton(this.label, this.kind);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InspectorCaptureScreen(kind: kind))),
        child: Text(label),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final FieldNote note;
  const _NoteCard(this.note);

  @override
  Widget build(BuildContext context) {
    final species = note.speciesId == null ? null : context.read<ContentRepository>().byId(note.speciesId!);
    final title = note.isPlant ? (species?.nameRu ?? 'Вид не указан') : note.kindLabel;
    final facts = [
      if (note.isPlant) _phases[note.phenophase],
      if (note.isPlant) _counts[note.abundance],
    ].whereType<String>().join(' · ');
    final when = _when(note.createdAt);
    final where = note.lat == null ? 'Координаты не указаны' : '${note.lat!.toStringAsFixed(5)}, ${note.lon!.toStringAsFixed(5)}';
    final photo = note.photoPath;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: paper,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InspectorCaptureScreen(note: note))),
          child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
              const Icon(Icons.edit_outlined, size: 18, color: moss),
            ]),
            if (facts.isNotEmpty) Text(facts, style: const TextStyle(color: forest)),
            if (note.text.isNotEmpty) Text(note.text, style: const TextStyle(height: 1.3)),
            const SizedBox(height: 4),
            Text([if (when.isNotEmpty) when, where].join(' · '), style: const TextStyle(color: moss, fontSize: 13)),
            if (photo != null && File(photo).existsSync()) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(photo), height: 120, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
          ]),
          ),
        ),
      ),
    );
  }
}

String _when(String iso) {
  final date = DateTime.tryParse(iso)?.toLocal();
  if (date == null || date.month < 1 || date.month > 12) return '';
  return '${date.day} ${monthNames[date.month - 1]}';
}

class InspectorCaptureScreen extends StatefulWidget {
  final String? kind;
  final FieldNote? note;
  const InspectorCaptureScreen({super.key, this.kind, this.note});

  @override
  State<InspectorCaptureScreen> createState() => _InspectorCaptureScreenState();
}

class _InspectorCaptureScreenState extends State<InspectorCaptureScreen> {
  late String _kind = widget.note?.kind ?? widget.kind ?? 'plant';
  late String _speciesId = widget.note?.speciesId ?? '';
  late String _phase = _phases.containsKey(widget.note?.phenophase) ? widget.note!.phenophase! : 'flowering';
  late String _count = _counts.containsKey(widget.note?.abundance) ? widget.note!.abundance! : '2-10';
  late final TextEditingController _text = TextEditingController(text: widget.note?.text ?? '');
  double? _savedLat;
  double? _savedLon;
  String? _photoPath;
  Position? _pos;
  String? _block;
  bool _locating = false;
  XFile? _photo;

  bool get _plant => _kind == 'plant';
  bool get _editing => widget.note != null;
  bool get _hasFreshPoint => _pos != null && _block == null;
  bool get _hasPoint => _hasFreshPoint || _savedLat != null;

  @override
  void initState() {
    super.initState();
    _savedLat = widget.note?.lat;
    _savedLon = widget.note?.lon;
    _photoPath = widget.note?.photoPath;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_speciesId.isNotEmpty && context.read<ContentRepository>().byId(_speciesId) == null) {
      _speciesId = '';
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    final result = await LocationService.current();
    if (!mounted) return;
    final position = result.position;
    setState(() {
      _locating = false;
      _pos = position;
      _block = position == null ? null : _reason(position);
    });
    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error!)));
    }
  }

  String? _reason(Position position) {
    final repo = context.read<ContentRepository>();
    final species = _speciesId.isEmpty ? null : repo.byId(_speciesId);
    final verdict = ParkProximity.evaluate(
      lat: position.latitude,
      lon: position.longitude,
      accuracyM: position.accuracy,
      fixTime: position.timestamp,
      now: DateTime.now(),
      mocked: position.isMocked,
      map: repo.map,
      speciesZoneIds: _plant ? (species?.parkZones ?? const []) : const [],
    );
    if (!verdict.allowed) return verdict.message;
    if (!_plant) return null;
    final duplicate = ParkProximity.duplicatesNearby(
      lat: position.latitude,
      lon: position.longitude,
      speciesId: _speciesId.isEmpty ? null : _speciesId,
      now: DateTime.now(),
      existing: [
        for (final note in context.read<ObservationController>().plants)
          if (note.id != widget.note?.id)
            (
              lat: note.lat,
              lon: note.lon,
              speciesId: note.speciesId,
              at: DateTime.tryParse(note.createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0),
            ),
      ],
    );
    if (duplicate) return 'Такое растение с этого места уже записано. Повторно добавлять его не нужно.';
    return null;
  }

  bool get _canSave {
    if (_plant) return _hasPoint && (_speciesId.isNotEmpty || _text.text.trim().isNotEmpty);
    return _text.text.trim().isNotEmpty;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source, maxWidth: 2048, imageQuality: 85);
    if (file != null) setState(() => _photo = file);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final lat = _hasFreshPoint ? _pos!.latitude : _savedLat;
    final lon = _hasFreshPoint ? _pos!.longitude : _savedLon;
    final photoPath = _photo?.path ?? _photoPath;
    final notes = context.read<ObservationController>();
    try {
      if (widget.note == null) {
        await notes.add(
          kind: _kind,
          text: _text.text,
          lat: lat,
          lon: lon,
          speciesId: _plant && _speciesId.isNotEmpty ? _speciesId : null,
          phenophase: _plant ? _phase : null,
          abundance: _plant ? _count : null,
          photoPath: photoPath,
        );
      } else {
        await notes.update(
          id: widget.note!.id,
          kind: _kind,
          text: _text.text,
          lat: lat,
          lon: lon,
          speciesId: _plant && _speciesId.isNotEmpty ? _speciesId : null,
          phenophase: _plant ? _phase : null,
          abundance: _plant ? _count : null,
          photoPath: photoPath,
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не удалось сохранить фото.')));
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: Text(_editing ? (_plant ? 'Изменить наблюдение' : 'Изменить отчёт') : (_plant ? 'Наблюдение' : 'Отчёт')),
        actions: [
          if (_editing)
            IconButton(
              tooltip: 'Удалить',
              onPressed: () async {
                await context.read<ObservationController>().remove(widget.note!.id);
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (!_plant)
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'territory', label: Text('Территория')),
              ButtonSegment(value: 'problem', label: Text('Проблема')),
            ],
            selected: {_kind == 'problem' ? 'problem' : 'territory'},
            onSelectionChanged: (value) => setState(() => _kind = value.first),
          ),
        if (_plant) ...[
          DropdownButtonFormField<String>(
            initialValue: _speciesId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Вид',
              filled: true,
              fillColor: paper,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Определение неуверенное')),
              for (final item in context.read<ContentRepository>().species) DropdownMenuItem(value: item.id, child: Text(item.nameRu)),
            ],
            onChanged: (value) => setState(() {
              _speciesId = value ?? '';
              final position = _pos;
              _block = position == null ? null : _reason(position);
            }),
          ),
          const SizedBox(height: 14),
          const Text('Состояние', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final item in _phases.entries)
              ChoiceChip(label: Text(item.value), selected: _phase == item.key, onSelected: (_) => setState(() => _phase = item.key)),
          ]),
          const SizedBox(height: 12),
          const Text('Сколько растений', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final item in _counts.entries)
              ChoiceChip(label: Text(item.value), selected: _count == item.key, onSelected: (_) => setState(() => _count = item.key)),
          ]),
        ],
        const SizedBox(height: 14),
        TextField(
          controller: _text,
          minLines: 3,
          maxLines: 6,
          onChanged: (_) => setState(() {}),
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: _plant ? 'Место, окружение, что именно видно' : 'След: свежий сбор, мусор, колея, костёр, техника',
            filled: true,
            fillColor: paper,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _locating ? null : _locate,
          icon: _locating
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location),
          label: Text(_pos != null
              ? '${_pos!.latitude.toStringAsFixed(5)}, ${_pos!.longitude.toStringAsFixed(5)}'
              : _savedLat != null
                  ? '${_savedLat!.toStringAsFixed(5)}, ${_savedLon!.toStringAsFixed(5)}'
                  : 'Определить координаты'),
        ),
        const SizedBox(height: 8),
        Text(_gpsHint, style: const TextStyle(color: moss, height: 1.3)),
        const SizedBox(height: 12),
        if (_photo != null || _photoPath != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.photo, color: forest),
            title: const Text('Фото прикреплено'),
            trailing: IconButton(
              onPressed: () => setState(() {
                _photo = null;
                _photoPath = null;
              }),
              icon: const Icon(Icons.close),
            ),
          ),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () => _pickPhoto(ImageSource.camera), icon: const Icon(Icons.photo_camera), label: const Text('Снять'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(onPressed: () => _pickPhoto(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('Из галереи'))),
        ]),
        const SizedBox(height: 16),
        FilledButton(onPressed: _canSave ? _save : null, child: const Text('Сохранить')),
      ]),
    );
  }

  String get _gpsHint {
    if (_pos == null && _savedLat != null) {
      return 'Координаты записи сохранены. Обновите их, только если стоите на месте.';
    }
    if (_plant && _pos == null) return 'Растение сохраняется только со свежими координатами рядом с местом находки.';
    if (_pos == null) return 'Координаты для отчёта желательны. Без них запись тоже сохранится.';
    return _block ?? (_plant ? 'Вы рядом с местом, растение можно записать.' : 'Координаты подойдут и будут сохранены с отчётом.');
  }
}

class InspectorStatsScreen extends StatelessWidget {
  const InspectorStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<ObservationController>();
    final territory = notes.reports.where((note) => note.kind == 'territory').length;
    final problems = notes.reports.where((note) => note.kind == 'problem').length;
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Статистика территории')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('${notes.plants.length}', style: const TextStyle(fontFamily: floraDisplay, fontSize: 48, color: forest)),
        const Text('наблюдений растений на этом устройстве', style: TextStyle(color: moss)),
        const SizedBox(height: 16),
        Text('${notes.reports.length}', style: const TextStyle(fontFamily: floraDisplay, fontSize: 48, color: forest)),
        const Text('отчётов о территории и проблемах', style: TextStyle(color: moss)),
        const SizedBox(height: 12),
        Text('Состояние территории: $territory'),
        Text('Проблемы: $problems'),
      ]),
    );
  }
}

class _InspectorBanner extends StatelessWidget {
  const _InspectorBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 188,
        child: Stack(children: [
          const Positioned.fill(child: Image(image: AssetImage('assets/images/cliffs.jpg'), fit: BoxFit.cover, alignment: Alignment.centerRight)),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(stops: [0, 0.46, 0.82], colors: [Color(0xFFF3F0E6), Color(0xD9F3F0E6), Color(0x00F3F0E6)]),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.spa, color: forest, size: 22),
                SizedBox(width: 8),
                Expanded(child: Text('Флора\nЛенских столбов', style: TextStyle(fontFamily: floraDisplay, fontSize: 20, height: 1.02, color: ink))),
              ]),
              SizedBox(height: 8),
              Row(children: [
                Icon(Icons.shield_outlined, color: forest, size: 18),
                SizedBox(width: 8),
                Text('Инспектор', style: TextStyle(fontFamily: floraDisplay, fontSize: 22, color: ink)),
              ]),
              SizedBox(height: 6),
              Text('Фиксируйте наблюдения,\nследите за состоянием\nтерритории и вносите данные', style: TextStyle(fontSize: 13, height: 1.25, color: moss)),
              SizedBox(height: 8),
              SizedBox(width: 42, height: 2, child: ColoredBox(color: forest)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _InspectorTile extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _InspectorTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

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
                  child: SvgPicture.asset(icon),
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
