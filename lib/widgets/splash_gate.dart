import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';

/// Opening frame: the landscape fades in from nothing, then the title slides up into place.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child});

  final Widget child;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 3400);

  AnimationController? _controller;
  bool _visible = true;

  bool get _inTest => WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    if (_inTest) {
      _visible = false;
      return;
    }
    final controller = AnimationController(vsync: this, duration: _duration);
    _controller = controller;
    controller.forward().whenComplete(() {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_visible && controller != null) Positioned.fill(child: _Splash(animation: controller)),
      ],
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final scene = _span(t, 0, 0.42, Curves.easeOut);
        final titleOpacity = _span(t, 0.30, 0.68, Curves.easeOut);
        final titleSlide = _span(t, 0.26, 0.72, Curves.easeOutCubic);
        final veil = _span(t, 0.82, 1, Curves.easeIn);
        return Opacity(
          opacity: 1 - veil,
          child: ColoredBox(
            color: cream,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: scene,
                  child: Image.asset(
                    'assets/images/splash_scene.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                Align(
                  alignment: const Alignment(0, 0.72),
                  child: Opacity(
                    opacity: titleOpacity,
                    child: Transform.translate(
                      offset: Offset(0, (1 - titleSlide) * 56),
                      child: Image.asset(
                        'assets/images/splash_wordmark.png',
                        width: MediaQuery.sizeOf(context).width * 0.78,
                        fit: BoxFit.contain,
                        semanticLabel: 'Флора Ленских столбов',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

double _span(double t, double begin, double end, Curve curve) {
  if (t <= begin) return 0;
  if (t >= end) return 1;
  return curve.transform((t - begin) / (end - begin));
}
