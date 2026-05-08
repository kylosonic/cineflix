import 'package:flutter/material.dart';

import '../../theme/motion_tokens.dart';
import 'fade_slide_in.dart';

class StaggeredReveal extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration initialDelay;
  final Duration step;
  final Duration duration;
  final Offset beginOffset;

  const StaggeredReveal({
    super.key,
    required this.child,
    required this.index,
    this.initialDelay = const Duration(milliseconds: 30),
    this.step = const Duration(milliseconds: 55),
    this.duration = CineMotion.medium,
    this.beginOffset = const Offset(0, 0.03),
  });

  @override
  Widget build(BuildContext context) {
    final computedDelay = Duration(
      milliseconds: initialDelay.inMilliseconds + (step.inMilliseconds * index),
    );

    return FadeSlideIn(
      delay: computedDelay,
      duration: duration,
      beginOffset: beginOffset,
      child: child,
    );
  }
}
