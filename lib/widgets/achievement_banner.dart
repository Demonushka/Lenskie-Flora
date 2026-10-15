import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/progress_controller.dart';
import '../theme/flora_theme.dart';

class AchievementBannerHost extends StatefulWidget {
  final Widget child;
  const AchievementBannerHost({super.key, required this.child});

  @override
  State<AchievementBannerHost> createState() => _AchievementBannerHostState();
}

class _AchievementBannerHostState extends State<AchievementBannerHost> with SingleTickerProviderStateMixin {
  late final AnimationController _slide;
  late final CurvedAnimation _curve;
  late final Animation<Offset> _offset;
  ProgressController? _progress;
  AchievementNotice? _notice;
  Timer? _hold;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _curve = CurvedAnimation(parent: _slide, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    _offset = Tween<Offset>(begin: const Offset(0, -1.4), end: Offset.zero).animate(_curve);
    _slide.addStatusListener((status) {
      if (status != AnimationStatus.dismissed || !_leaving) return;
      _leaving = false;
      if (!mounted) return;
      setState(() => _notice = null);
      _showNext();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final progress = context.read<ProgressController>();
    if (_progress == progress) return;
    _progress?.removeListener(_showNext);
    _progress = progress..addListener(_showNext);
    _showNext();
  }

  @override
  void dispose() {
    _hold?.cancel();
    _progress?.removeListener(_showNext);
    _curve.dispose();
    _slide.dispose();
    super.dispose();
  }

  void _showNext() {
    if (_notice != null || !mounted) return;
    final pending = _progress?.notices;
    if (pending == null || pending.isEmpty) return;
    setState(() => _notice = pending.removeAt(0));
    _slide.forward(from: 0);
    _hold?.cancel();
    _hold = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      _leaving = true;
      _slide.reverse();
    });
  }

  void _dismiss() {
    if (_notice == null || _leaving) return;
    _hold?.cancel();
    _leaving = true;
    _slide.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final notice = _notice;
    return Stack(children: [
      widget.child,
      if (notice != null)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: SlideTransition(
                position: _offset,
                child: Material(
                  color: paper,
                  elevation: 8,
                  shadowColor: const Color(0x331B4636),
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: _dismiss,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                      child: Row(children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: Color(0xFFF2C94C),
                          child: Icon(Icons.emoji_events, color: Color(0xFF8A5A2A)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('ДОСТИЖЕНИЕ', style: TextStyle(letterSpacing: 1.1, fontSize: 11, fontWeight: FontWeight.w800, color: moss)),
                            Text(notice.title, style: const TextStyle(fontFamily: floraDisplay, fontSize: 22, height: 1.05, color: ink)),
                            const SizedBox(height: 2),
                            Text(notice.description, style: const TextStyle(fontSize: 13, height: 1.25, color: moss)),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}
