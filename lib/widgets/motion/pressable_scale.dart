import 'package:flutter/material.dart';

import '../../theme/motion_tokens.dart';

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final double hoveredScale;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.98,
    this.hoveredScale = 1.015,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final reduce = CineMotion.reduceMotion(context);
    final scale = reduce
        ? 1.0
        : (_pressed
              ? widget.pressedScale
              : (_hovered ? widget.hoveredScale : 1.0));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: widget.onTap == null
            ? null
            : () => setState(() => _pressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          duration: CineMotion.resolveDuration(context, CineMotion.fast),
          curve: CineMotion.resolveCurve(context, CineMotion.standardCurve),
          scale: scale,
          child: widget.child,
        ),
      ),
    );
  }
}
