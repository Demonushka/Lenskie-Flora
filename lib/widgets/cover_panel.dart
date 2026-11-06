import 'package:flutter/material.dart';

/// Photo panel that keeps a design height when the text fits and grows
/// instead of clipping when the screen is narrow or the system font is large.
class CoverPanel extends StatelessWidget {
  final double minHeight;
  final Widget background;
  final EdgeInsetsGeometry padding;
  final List<Widget> children;
  final BorderRadius borderRadius;

  const CoverPanel({
    super.key,
    required this.minHeight,
    required this.background,
    required this.children,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        children: [
          Positioned.fill(child: background),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
