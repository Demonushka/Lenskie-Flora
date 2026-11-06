import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/content_repository.dart';
import '../logic/catalog_cards.dart';
import '../logic/flower_vision.dart';
import '../logic/identification_key.dart';
import '../models/labels.dart';
import '../models/species.dart';
import '../state/progress_controller.dart';
import '../state/session_controller.dart';
import '../theme/flora_theme.dart';
import '../widgets/beta_mark.dart';
import '../widgets/glossary_text.dart';
import '../widgets/species_image.dart';
import 'species_detail_screen.dart';

class KeyScreen extends StatefulWidget {
  const KeyScreen({super.key});

  @override
  State<KeyScreen> createState() => _KeyScreenState();
}

class _KeyScreenState extends State<KeyScreen> {
  late final IdentificationKey _key = IdentificationKey(context.read<ContentRepository>().species);
  int _generation = 0;
  bool _started = false;
  XFile? _photo;
  bool _matching = false;
  String? _matchedId;
  int? _matchedPercent;
  int _matchToken = 0;
  SessionController? _session;

  bool get _consumesBack => _key.canUndo || _started || _photo != null || _matching;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _publishBack());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _session = context.read<SessionController>();
  }

  @override
  void dispose() {
    _session?.bindBack(null, handles: false, notify: false);
    super.dispose();
  }

  void _publishBack() {
    if (!mounted) return;
    final session = _session;
    if (session == null) return;
    final onIdentify = session.role == 'tourist' && session.tab == 2 && !Navigator.canPop(context);
    session.bindBack(_onSystemBack, handles: onIdentify && _consumesBack);
  }

  bool _onSystemBack() {
    if (!mounted) return false;
    final session = _session;
    if (session == null || session.tab != 2 || Navigator.canPop(context)) return false;
    return _retreat();
  }

  bool _retreat() {
    _matchToken++;
    if (_key.canUndo) {
      setState(_key.undo);
      return true;
    }
    if (_started || _photo != null || _matching) {
      _again();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final generation = context.watch<SessionController>().identifyGeneration;
    if (generation != _generation) {
      _generation = generation;
      _started = false;
      _photo = null;
      _matching = false;
      _matchedId = null;
      _matchedPercent = null;
      _key.reset();
    }
    final question = _started ? _key.nextQuestion() : null;

    final pushed = Navigator.canPop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _publishBack());
    return PopScope(
      canPop: !pushed || !_consumesBack,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !pushed) return;
        _retreat();
      },
      child: Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Column(children: [
          if (_consumesBack || pushed)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Назад',
                onPressed: () {
                  if (_retreat()) return;
                  if (pushed) Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back, color: ink),
              ),
            ),
          Expanded(child: !_started
            ? _Intro(
                photo: _photo,
                matching: _matching,
                matched: _matchedId == null ? null : context.read<ContentRepository>().byId(_matchedId!),
                percent: _matchedPercent,
                onCamera: () => _pick(ImageSource.camera),
                onGallery: () => _pick(ImageSource.gallery),
                onOpenMatch: _matchedId == null
                    ? null
                    : () {
                        final species = context.read<ContentRepository>().byId(_matchedId!);
                        if (species == null) return;
                        Navigator.push(context, MaterialPageRoute(builder: (_) => SpeciesDetailScreen(species: species)));
                      },
                onStart: () => setState(() => _started = true),
              )
            : question == null
                ? _ResultView(
                    keyState: _key,
                    onAgain: _again,
                    onOpen: (species) => Navigator.push(context, MaterialPageRoute(builder: (_) => SpeciesDetailScreen(species: species))),
                  )
                : _Questions(
                    question: question,
                    onAnswer: (value) {
                      setState(() => _key.answer(question.trait, value));
                      _recordCertain();
                    },
                    onUndo: _key.canUndo ? () => setState(_key.undo) : null,
                  ),
          ),
        ]),
      ),
    ),
    );
  }

  Future<void> _pick(ImageSource source) async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    } on StateError {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Камера на этом компьютере недоступна. Выберите фото из галереи.')),
      );
      return;
    }
    if (file == null || !mounted) return;
    final token = ++_matchToken;
    setState(() {
      _photo = file;
      _matching = true;
      _matchedId = null;
      _matchedPercent = null;
    });
    final bytes = await file.readAsBytes();
    if (!mounted || token != _matchToken || _photo?.path != file.path) return;
    final guess = await CatalogCards.guess(bytes, context.read<ContentRepository>().species);
    if (!mounted || token != _matchToken || _photo?.path != file.path) return;
    setState(() {
      _matching = false;
      _matchedId = guess?.speciesId;
      _matchedPercent = guess == null ? null : (guess.probability * 100).round().clamp(1, 99);
    });
  }

  void _recordCertain() {
    final found = _key.candidates;
    if (found.length != 1) return;
    context.read<ProgressController>().markIdentified(found.first.id, nameRu: found.first.nameRu);
  }

  void _again() => setState(() {
        _started = false;
        _photo = null;
        _matching = false;
        _matchedId = null;
        _matchedPercent = null;
        _key.reset();
      });
}

class _Intro extends StatelessWidget {
  final XFile? photo;
  final bool matching;
  final Species? matched;
  final int? percent;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback? onOpenMatch;
  final VoidCallback onStart;

  const _Intro({
    required this.photo,
    required this.matching,
    required this.matched,
    required this.percent,
    required this.onCamera,
    required this.onGallery,
    required this.onOpenMatch,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), children: [
      const Text('ОПРЕДЕЛЕНИЕ ПО ФОТО', style: TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.w800, color: forest)),
      const SizedBox(height: 4),
      const Text('Флора Ленских столбов', style: TextStyle(color: moss)),
      const SizedBox(height: 16),
      ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 220,
          child: photo == null
              ? Image.asset('assets/images/calypso.jpg', fit: BoxFit.cover)
              : Image.file(File(photo!.path), fit: BoxFit.cover),
        ),
      ),
      const SizedBox(height: 16),
      const Row(children: [
        Text('НЕЙРОСЕТЬ', style: TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.w800, color: forest, fontSize: 13)),
        SizedBox(width: 8),
        BetaMark(),
      ]),
      const SizedBox(height: 6),
      Text(
        FlowerVision.status(hasPhoto: photo != null, matching: matching, speciesName: matched?.nameRu, percent: percent),
        style: const TextStyle(fontSize: 16, height: 1.35),
      ),
      if (percent != null) ...[
        const SizedBox(height: 8),
        Text('$percent%', style: const TextStyle(fontFamily: floraDisplay, fontSize: 40, height: 1, color: forest)),
        const Text('предполагаемая вероятность', style: TextStyle(color: moss)),
      ],
      if (onOpenMatch != null) ...[
        const SizedBox(height: 10),
        FilledButton(onPressed: onOpenMatch, child: const Text('Открыть карточку')),
      ],
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: onCamera, icon: const Icon(Icons.photo_camera_outlined), label: const Text('Сфотографировать')),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: onGallery, icon: const Icon(Icons.photo_library_outlined), label: const Text('Из галереи')),
      const SizedBox(height: 10),
      FilledButton(onPressed: onStart, child: const Text('Начать по признакам')),
    ]);
  }
}

class _Questions extends StatelessWidget {
  final KeyQuestion question;
  final ValueChanged<String> onAnswer;
  final VoidCallback? onUndo;

  const _Questions({required this.question, required this.onAnswer, this.onUndo});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), children: [
      const Text('ОПРЕДЕЛЕНИЕ ПО ПРИЗНАКАМ', style: TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.w800, color: forest)),
      const SizedBox(height: 16),
      GlossaryText(question.title, style: const TextStyle(fontFamily: floraDisplay, fontSize: 32, height: 1.1, color: ink)),
      const SizedBox(height: 6),
      GlossaryText(question.hint, style: const TextStyle(fontSize: 16, color: moss, height: 1.35)),
      const SizedBox(height: 16),
      for (final option in question.options)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: paper,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onAnswer(option.value),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(children: [
                  Expanded(child: GlossaryText(option.label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: ink))),
                  Text('${option.count}', style: const TextStyle(color: moss)),
                ]),
              ),
            ),
          ),
        ),
      OutlinedButton(onPressed: () => onAnswer(unknownAnswer), child: const Text('Не знаю')),
      if (onUndo != null) TextButton.icon(onPressed: onUndo, icon: const Icon(Icons.undo), label: const Text('Назад')),
    ]);
  }
}

class _ResultView extends StatelessWidget {
  final IdentificationKey keyState;
  final VoidCallback onAgain;
  final ValueChanged<Species> onOpen;

  const _ResultView({required this.keyState, required this.onAgain, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final pool = keyState.candidates;
    if (pool.isEmpty) {
      final near = keyState.nearMatches;
      return ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Точного совпадения нет', style: TextStyle(fontFamily: floraDisplay, fontSize: 32)),
        const SizedBox(height: 8),
        const Text('Значок вида не открывается: ответы не сходятся с одним растением из каталога.'),
        if (near.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Ближе всего:'),
          for (final item in near)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.nameRu),
              onTap: () => onOpen(item),
            ),
        ],
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onAgain, child: const Text('Ещё раз')),
      ]);
    }
    if (pool.length > 1) {
      return ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Осталось несколько видов', style: TextStyle(fontFamily: floraDisplay, fontSize: 32)),
        const SizedBox(height: 8),
        const Text('Значок откроется, когда ответы оставят один вид. Сейчас подходящих растений больше одного.'),
        const SizedBox(height: 12),
        for (final item in pool)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.nameRu),
            subtitle: Text(item.nameLat, style: const TextStyle(fontStyle: FontStyle.italic)),
            onTap: () => onOpen(item),
          ),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onAgain, child: const Text('Ещё раз')),
      ]);
    }
    final species = pool.first;
    final similar = _similar(species, pool.length > 1 ? pool.skip(1).toList() : keyState.all);
    final accuracy = _accuracy(species);

    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20), children: [
      const Text('ОПРЕДЕЛЕНИЕ ПО ПРИЗНАКАМ', style: TextStyle(letterSpacing: 1.1, fontWeight: FontWeight.w800, color: forest, fontSize: 13)),
      const SizedBox(height: 2),
      const Text('Флора Ленских столбов', style: TextStyle(color: moss)),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 210,
          width: double.infinity,
          child: SpeciesThumb(species: species),
        ),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Вероятный результат:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Text(species.nameRu, style: const TextStyle(fontFamily: floraDisplay, fontSize: 30, height: 1.15)),
          Text(species.nameLat, style: const TextStyle(fontStyle: FontStyle.italic, color: moss)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (accuracy != null) _Pill(chipGreen, forest, 'Точность: $accuracy%'),
            if (species.statusRf != null) const _Pill(chipRed, chipRedText, 'Красная книга РФ'),
            if (species.statusRf == null && species.statusRsya != null) const _Pill(chipRed, chipRedText, 'Красная книга РС(Я)'),
          ]),
          const SizedBox(height: 12),
          Text('Среда: ${_habitat(species)}'),
          const SizedBox(height: 4),
          Text('Цветение: ${monthsRange(species.floweringMonths)}'),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: FilledButton(onPressed: () => onOpen(species), child: const Text('Подробнее  ›'))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton(onPressed: onAgain, child: const Text('Ещё раз'))),
          ]),
        ]),
      ),
      if (similar.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(24)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Похожие виды', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(spacing: 16, children: [
              for (final item in similar)
                GestureDetector(
                  onTap: () => onOpen(item),
                  child: Text(item.nameRu, style: const TextStyle(decoration: TextDecoration.underline)),
                ),
            ]),
          ]),
        ),
      ],
    ]);
  }

  int? _accuracy(Species species) {
    final answered = keyState.answers.values.where((value) => value != unknownAnswer).length;
    if (answered == 0) return null;
    final score = ((answered - keyState.mismatches(species)) / answered * 100).round();
    return score.clamp(0, 100);
  }

  List<Species> _similar(Species species, List<Species> preferred) {
    final list = preferred.where((item) => item.id != species.id).toList();
    if (list.isNotEmpty) return list.take(2).toList();
    return keyState.all.where((item) => item.id != species.id && item.family == species.family).take(2).toList();
  }

  String _habitat(Species species) {
    if (species.habitatText.isNotEmpty) {
      final text = species.habitatText;
      return text.length > 80 ? '${text.substring(0, 77)}…' : text;
    }
    if (species.habitats.isEmpty) return 'нет данных';
    return habitatLabels[species.habitats.first] ?? species.habitats.first;
  }
}

class _Pill extends StatelessWidget {
  final Color background;
  final Color foreground;
  final String text;
  const _Pill(this.background, this.foreground, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: foreground, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}
