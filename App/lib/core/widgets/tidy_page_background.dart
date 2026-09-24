import 'package:flutter/material.dart';

import '../design/tidy_colors.dart';

class TidyPageBackground extends StatelessWidget {
  const TidyPageBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: TidyColors.background,
      gradient: RadialGradient(
        center: Alignment(0.95, -0.5),
        radius: 0.8,
        colors: <Color>[
          TidyColors.backgroundVioletGlow,
          TidyColors.backgroundVioletClear,
        ],
      ),
    ),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-1, 0.4),
          radius: 0.8,
          colors: <Color>[
            TidyColors.backgroundPinkGlow,
            TidyColors.backgroundPinkClear,
          ],
        ),
      ),
      child: child,
    ),
  );
}
