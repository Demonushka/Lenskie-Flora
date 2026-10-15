import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';

const glossary = <String, String>{
  'форма листьев': 'Общий контур листа. У редких видов парка по ней удобно отличать злаки, орхидеи и растения с разрезанной пластинкой.',
  'линейные': 'Лист длинный и почти одинаково узкий по всей длине, как у ириса или лука.',
  'ланцетные': 'Лист в несколько раз длиннее ширины: шире всего ниже середины и сужается к верхушке, как наконечник копья.',
  'овальные': 'Лист округлый, вытянутый, шире всего посередине.',
  'яйцевидные': 'Лист похож на яйцо: шире у основания и уже к кончику.',
  'сердцевидные': 'У основания листа есть выемка, а сама пластинка округлая, как у кувшинки.',
  'округлые': 'Пластинка почти круглая, без длинного кончика.',
  'рассечённые': 'Пластинка разрезана почти до основания на доли. Так выглядят листья адониса и мака.',
  'лопастные': 'Край листа разрезан неглубоко, доли широкие.',
  'сложные': 'Лист состоит из отдельных листочков на одном черешке, а не из одной пластинки.',
  'листочков': 'Отдельные маленькие пластинки, из которых собран сложный лист.',
  'игольчатые': 'Лист жёсткий и похож на иглу, как хвоя.',
  'чешуйчатые': 'Листья мелкие и прижаты к стеблю, как чешуйки.',
  'травянистое': 'Стебель мягкий и зелёный, на зиму отмирает. Это не куст и не дерево.',
  'кустарничек': 'Низкое деревянистое растение, обычно ниже колена.',
  'полукустарник': 'Нижняя часть стебля деревянистая, верхняя травянистая и зимой отмирает.',
  'кустарник': 'Деревянистое растение с несколькими стволиками, без одного главного ствола.',
  'папоротник': 'Растение без цветков. Размножается спорами, листья часто перистые.',
  'венчик': 'Окрашенные лепестки цветка, то, что обычно называют «цветком».',
  'тукуланы': 'Песчаные дюны. В парке это светлые пески по берегам и долинам.',
  'осыпи': 'Склон из подвижных камней под скалами.',
};

class GlossaryText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const GlossaryText(this.text, {super.key, this.style});

  @override
  State<GlossaryText> createState() => _GlossaryTextState();
}

class _GlossaryTextState extends State<GlossaryText> {
  final List<TapGestureRecognizer> _recognizers = [];
  List<InlineSpan> _spans = const [];
  static final _pattern = RegExp(
    (glossary.keys.toList()..sort((a, b) => b.length.compareTo(a.length))).map(RegExp.escape).join('|'),
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();
    _spans = _buildSpans();
  }

  @override
  void didUpdateWidget(GlossaryText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      for (final recognizer in _recognizers) {
        recognizer.dispose();
      }
      _recognizers.clear();
      _spans = _buildSpans();
    }
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  void _open(String term) {
    final key = glossary.keys.firstWhere((k) => k.toLowerCase() == term.toLowerCase());
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(key, style: const TextStyle(fontFamily: floraDisplay, fontSize: 28, color: ink)),
          const SizedBox(height: 8),
          Text(glossary[key]!, style: const TextStyle(fontSize: 16, height: 1.4)),
        ]),
      ),
    );
  }

  List<InlineSpan> _buildSpans() {
    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in _pattern.allMatches(widget.text)) {
      if (match.start < start) continue;
      if (match.start > start) {
        spans.add(TextSpan(text: widget.text.substring(start, match.start)));
      }
      final term = match.group(0)!;
      final recognizer = TapGestureRecognizer()..onTap = () => _open(term);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: term,
        recognizer: recognizer,
        style: const TextStyle(
          color: forest,
          decoration: TextDecoration.underline,
          decorationColor: forest,
          fontWeight: FontWeight.w700,
        ),
      ));
      start = match.end;
    }
    if (start < widget.text.length) spans.add(TextSpan(text: widget.text.substring(start)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(TextSpan(style: widget.style, children: _spans));
  }
}
