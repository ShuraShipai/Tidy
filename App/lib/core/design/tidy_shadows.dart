import 'package:flutter/material.dart';

import 'tidy_colors.dart';

abstract final class TidyShadows {
  static const List<BoxShadow> orb = <BoxShadow>[
    BoxShadow(
      color: TidyColors.orbShadow,
      offset: Offset(6, 9),
      blurRadius: 14,
    ),
    BoxShadow(color: Color(0xBFFFFFFF), offset: Offset(-4, -4), blurRadius: 12),
  ];

  static const List<BoxShadow> action = <BoxShadow>[
    BoxShadow(color: Color(0x307C3AED), offset: Offset(4, 7), blurRadius: 13),
  ];

  static const List<BoxShadow> raised = <BoxShadow>[
    BoxShadow(color: Color(0x30B7A8CF), offset: Offset(8, 12), blurRadius: 24),
    BoxShadow(color: Color(0xCFFFFFFF), offset: Offset(-5, -5), blurRadius: 15),
    BoxShadow(color: Color(0x55D7CBEA), offset: Offset(-2, -3), blurRadius: 5),
    BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(2, 2), blurRadius: 3),
  ];

  static const List<BoxShadow> pressed = <BoxShadow>[
    BoxShadow(color: Color(0x60C8B9DC), offset: Offset(3, 4), blurRadius: 8),
    BoxShadow(color: TidyColors.surface, offset: Offset(-3, -3), blurRadius: 8),
  ];
}
