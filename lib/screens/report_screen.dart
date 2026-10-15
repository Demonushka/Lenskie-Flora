import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../logic/park_proximity.dart';
import '../services/location_service.dart';
import '../state/outbox_controller.dart';
import '../state/progress_controller.dart';

const _phenophases = {
  'vegetation': 'Вегетация (без цветков)',
  'budding': 'Бутонизация',
  'flowering': 'Цветение',
  'fruiting': 'Плодоношение',
};

const _abundance = {
  '1': '1 растение',
  '2-10': '2–10 растений',
  '11-50': '11–50 растений',
  '50+': 'Больше 50',
};

class ReportScreen extends StatefulWidget {
  final String? initialSpeciesId;
  const ReportScreen({super.key, this.initialSpeciesId});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late String _speciesId = widget.initialSpeciesId ?? '';
  String _phase = 'flowering';
  String _count = '2-10';
  final _comment = TextEditingController();
  final _contact = TextEditingController();
  bool _consent = false;
  Position? _pos;
  String? _geoError;
  String? _block;
  bool _locating = false;
  XFile? _photo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _locate();
  }

  @override
  void dispose() {
    _comment.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _geoError = null;
    });
    final r = await LocationService.current();
    if (!mounted) return;
    setState(() {
      _locating = false;
      _pos = r.position ?? _pos;
      _geoError = r.error;
      _block = _reason(_pos);
    });
  }

  String? _reason(Position? position) {
    if (position == null) return null;
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
      speciesZoneIds: species?.parkZones ?? const [],
    );
    if (!verdict.allowed) return verdict.message;
    final speciesId = _speciesId.isEmpty ? null : _speciesId;
    final duplicate = ParkProximity.duplicatesNearby(
      lat: position.latitude,
      lon: position.longitude,
      speciesId: speciesId,
      now: DateTime.now(),
      existing: [
        for (final item in context.read<OutboxController>().items)
          if (item.type == OutboxType.report)
            (
              lat: (item.payload['lat'] as num?)?.toDouble(),
              lon: (item.payload['lon'] as num?)?.toDouble(),
              speciesId: item.payload['speciesId'] as String?,
              at: item.createdAt,
            ),
      ],
    );
    if (duplicate) {
      return 'Такой цветок с этого места уже есть в списке. Повторно его добавить нельзя.';
    }
    return null;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final f = await ImagePicker().pickImage(source: source, maxWidth: 2048, imageQuality: 85);
    if (f != null) setState(() => _photo = f);
  }

  bool get _canSubmit =>
      !_saving && _pos != null && _block == null && (_contact.text.trim().isEmpty || _consent);

  Future<void> _submit() async {
    setState(() => _saving = true);
    final outbox = context.read<OutboxController>();
    final progress = context.read<ProgressController>();
    final p = _pos!;
    await outbox.add(
      OutboxType.report,
      {
        'speciesId': _speciesId.isEmpty ? null : _speciesId,
        'phenophase': _phase,
        'abundance': _count,
        'comment': _comment.text.trim(),
        'lat': p.latitude,
        'lon': p.longitude,
        'accuracyM': p.accuracy,
        'altitudeM': p.altitude,
        'observedAt': (p.timestamp).toIso8601String(),
        if (_contact.text.trim().isNotEmpty) 'contact': _contact.text.trim(),
      },
      photoPath: _photo?.path,
    );
    await progress.addReport();
    if (!mounted) return;
    final msg = outbox.syncEnabled
        ? 'Сообщение сохранено и будет отправлено в научный отдел при появлении интернета'
        : 'Сообщение сохранено. Передайте данные через «Ещё → Мои данные»';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$msg (+${Points.report} баллов)')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final species = context.read<ContentRepository>().species;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Сообщить о находке')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text(
          'Ваше наблюдение поможет научному отделу парка следить за редкими растениями. '
          'Точные координаты получают только специалисты парка — в приложении они не публикуются.',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _speciesId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Вид растения', border: OutlineInputBorder()),
          items: [
            const DropdownMenuItem(value: '', child: Text('Не знаю / другой вид')),
            for (final s in species) DropdownMenuItem(value: s.id, child: Text(s.nameRu)),
          ],
          onChanged: (v) => setState(() {
            _speciesId = v ?? '';
            _block = _reason(_pos);
          }),
        ),
        const SizedBox(height: 16),
        Text('Состояние растения', style: theme.textTheme.titleMedium),
        Wrap(spacing: 8, children: [
          for (final e in _phenophases.entries)
            ChoiceChip(label: Text(e.value), selected: _phase == e.key, onSelected: (_) => setState(() => _phase = e.key)),
        ]),
        const SizedBox(height: 12),
        Text('Сколько растений', style: theme.textTheme.titleMedium),
        Wrap(spacing: 8, children: [
          for (final e in _abundance.entries)
            ChoiceChip(label: Text(e.value), selected: _count == e.key, onSelected: (_) => setState(() => _count = e.key)),
        ]),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: _locating
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_pos != null ? Icons.gps_fixed : Icons.gps_off),
            title: Text(_pos != null
                ? '${_pos!.latitude.toStringAsFixed(5)}, ${_pos!.longitude.toStringAsFixed(5)}'
                : _locating
                    ? 'Определяем координаты…'
                    : 'Координаты не определены'),
            subtitle: Text(_pos != null ? 'Точность ±${_pos!.accuracy.round()} м' : (_geoError ?? 'GPS работает без интернета')),
            trailing: IconButton(icon: const Icon(Icons.refresh), tooltip: 'Обновить', onPressed: _locating ? null : _locate),
          ),
        ),
        const SizedBox(height: 12),
        if (_photo != null)
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Фото прикреплено'),
            trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _photo = null)),
          ),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.photo_camera),
              label: const Text('Снять'),
              onPressed: () => _pickPhoto(ImageSource.camera),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Из галереи'),
              onPressed: () => _pickPhoto(ImageSource.gallery),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        TextField(
          controller: _comment,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Комментарий (место, окружение, угрозы)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _contact,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Контакт для связи (необязательно)',
            hintText: 'Имя, телефон или e-mail',
            border: OutlineInputBorder(),
          ),
        ),
        if (_contact.text.trim().isNotEmpty)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _consent,
            onChanged: (v) => setState(() => _consent = v ?? false),
            title: const Text('Согласен(на) на обработку персональных данных национальным парком для связи по этой находке'),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
          label: const Text('Сохранить сообщение'),
          onPressed: _canSubmit ? _submit : null,
        ),
        if (_pos == null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Для отправки нужны координаты места находки.', textAlign: TextAlign.center),
          )
        else if (_block != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_block!, textAlign: TextAlign.center),
          )
        else
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Вы рядом с местом находки, запись можно сохранить.', textAlign: TextAlign.center),
          ),
        const SizedBox(height: 24),
      ]),
    );
  }
}
