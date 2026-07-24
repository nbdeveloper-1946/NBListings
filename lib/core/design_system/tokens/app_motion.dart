import 'package:flutter/animation.dart';

/// Motion tokens for consistent, premium animations.
class CRMMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounce = Curves.easeOutBack;

  static const SpringDescription spring = SpringDescription(
    mass: 1,
    stiffness: 180,
    damping: 20,
  );

  static const SpringDescription interactiveSpring = SpringDescription(
    mass: 0.8,
    stiffness: 300,
    damping: 22,
  );

  static const Curve springCurve = Curves.easeOutCubic;
}
