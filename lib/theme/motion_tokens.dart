import 'package:flutter/material.dart';

class CineMotion {
  const CineMotion._();

  static const Duration instant = Duration(milliseconds: 1);
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 420);

  static const Curve emphasizeCurve = Curves.easeOutCubic;
  static const Curve standardCurve = Curves.easeOut;
  static const Curve entranceCurve = Curves.easeOutQuart;

  static bool reduceMotion(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    if (media == null) return false;
    return media.disableAnimations || media.accessibleNavigation;
  }

  static Duration resolveDuration(
    BuildContext context,
    Duration duration, {
    Duration reduced = instant,
  }) {
    return reduceMotion(context) ? reduced : duration;
  }

  static Curve resolveCurve(
    BuildContext context,
    Curve curve, {
    Curve reduced = Curves.linear,
  }) {
    return reduceMotion(context) ? reduced : curve;
  }

  static Offset resolveOffset(BuildContext context, Offset offset) {
    return reduceMotion(context) ? Offset.zero : offset;
  }
}
