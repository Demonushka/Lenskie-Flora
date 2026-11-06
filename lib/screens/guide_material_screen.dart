import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/excursion.dart';
import '../state/excursion_controller.dart';
import '../theme/flora_theme.dart';

const materialFileExtensions = ['pdf', 'txt', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'webp', 'heic'];

bool materialIsImage(String? name) {
  final lower = (name ?? '').toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.gif');
}

Future<void> addGuideMaterial(BuildContext context) async {
  final tours = context.read<ExcursionController>();
  if (tours.items.isEmpty) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Нет экскурсии'),
        content: const Text('Сначала создайте экскурсию. Материал прикрепляется к ней.'),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Понятно'))],
      ),
    );
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (context) => _MaterialDialog(excursions: [...tours.items], tours: tours),
  );
}

Future<bool> confirmRemoveMaterial(BuildContext context, String excursionId, String materialId) async {
  final remove = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Удалить материал?'),
      content: const Text('Текст и файл будут стёрты с этого телефона.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
      ],
    ),
  );
  if (remove != true || !context.mounted) return false;
  await context.read<ExcursionController>().removeMaterial(excursionId, materialId);
  return true;
}

class GuideMaterialArticle extends StatelessWidget {
  final String excursionId;
  final String excursionTitle;
  final ExcursionMaterial material;

  const GuideMaterialArticle({
    super.key,
    required this.excursionId,
    required this.excursionTitle,
    required this.material,
  });

  @override
  Widget build(BuildContext context) {
    final path = material.filePath;
    final file = path == null ? null : File(path);
    final fileReady = file != null && file.existsSync();
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Материал'),
        actions: [
          IconButton(
            tooltip: 'Удалить материал',
            onPressed: () async {
              final removed = await confirmRemoveMaterial(context, excursionId, material.id);
              if (removed && context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(material.title, style: const TextStyle(fontFamily: floraDisplay, fontSize: 32, height: 1.05, color: ink)),
          const SizedBox(height: 8),
          Text(excursionTitle, style: const TextStyle(color: moss, fontSize: 16)),
          if (material.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(material.text, style: const TextStyle(fontSize: 16, height: 1.45, color: ink)),
          ],
          if (material.hasFile) ...[
            const SizedBox(height: 16),
            if (fileReady && materialIsImage(material.fileName))
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(file, fit: BoxFit.cover),
              )
            else
              Text(
                fileReady ? (material.fileName ?? 'Файл') : 'Файл не найден на этом телефоне',
                style: const TextStyle(color: moss),
              ),
          ],
          if (fileReady || material.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => SharePlus.instance.share(ShareParams(
                files: fileReady ? [XFile(file.path)] : null,
                text: material.text.isEmpty ? null : material.text,
                subject: material.title,
              )),
              icon: const Icon(Icons.ios_share),
              label: const Text('Открыть в другом приложении'),
            ),
          ],
        ],
      ),
    );
  }
}

class _MaterialDialog extends StatefulWidget {
  final List<Excursion> excursions;
  final ExcursionController tours;

  const _MaterialDialog({required this.excursions, required this.tours});

  @override
  State<_MaterialDialog> createState() => _MaterialDialogState();
}

class _MaterialDialogState extends State<_MaterialDialog> {
  late String _excursionId = widget.excursions.first.id;
  final _title = TextEditingController();
  final _text = TextEditingController();
  String? _titleError;
  String? _fileError;
  String? _keptPath;
  String? _keptName;
  bool _saved = false;
  bool _picking = false;

  @override
  void dispose() {
    if (!_saved && _keptPath != null) unawaited(widget.tours.discardKeptFile(_keptPath!));
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() {
      _picking = true;
      _fileError = null;
    });
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Материал для экскурсии',
        type: FileType.custom,
        allowedExtensions: materialFileExtensions,
      );
      if (file == null) return;
      final path = file.path;
      final kept = path != null
          ? await widget.tours.keepMaterialFile(path, file.name)
          : await widget.tours.keepMaterialBytes(await file.readAsBytes(), file.name);
      if (!mounted) return;
      if (kept == null) {
        setState(() => _fileError = 'Не удалось прочитать файл');
        return;
      }
      final previous = _keptPath;
      setState(() {
        _keptPath = kept.path;
        _keptName = kept.name;
      });
      if (previous != null) unawaited(widget.tours.discardKeptFile(previous));
    } catch (_) {
      if (mounted) setState(() => _fileError = 'Не удалось открыть файлы');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Укажите название материала');
      return;
    }
    await widget.tours.addMaterial(
      excursionId: _excursionId,
      title: title,
      text: _text.text,
      fileName: _keptName,
      filePath: _keptPath,
    );
    _saved = true;
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Авторский материал'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            DropdownButtonFormField<String>(
              initialValue: _excursionId,
              decoration: const InputDecoration(labelText: 'Экскурсия'),
              items: [
                for (final tour in widget.excursions) DropdownMenuItem(value: tour.id, child: Text(tour.title)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _excursionId = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('material-title'),
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: 'Название', errorText: _titleError),
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('material-text'),
              controller: _text,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Текст', alignLabelWithHint: true),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _picking ? null : _pick,
              icon: const Icon(Icons.upload_file),
              label: Text(_keptName ?? 'Прикрепить файл'),
            ),
            if (_fileError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_fileError!, style: const TextStyle(color: Colors.red)),
              ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(onPressed: _picking ? null : _save, child: const Text('Сохранить')),
      ],
    );
  }
}
