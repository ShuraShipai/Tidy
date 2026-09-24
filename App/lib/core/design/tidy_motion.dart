import 'package:flutter/animation.dart';

abstract final class TidyMotion {
  static const splashDuration = Duration(milliseconds: 1200);
  static const pressDuration = Duration(milliseconds: 200);
  static const pressScale = 0.965;
  static const pressCurve = Cubic(0.22, 1, 0.36, 1);
}
