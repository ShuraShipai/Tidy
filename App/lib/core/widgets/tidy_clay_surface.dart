import 'package:flutter/material.dart';

import '../design/tidy_colors.dart';

/// The inset highlights used by the approved clay controls and illustrations.
class TidyClaySurface extends StatelessWidget {
  const TidyClaySurface({
    required this.child,
    required this.radius,
    required this.shadows,
    this.color,
    this.gradient,
    super.key,
  });

  final Widget child;
  final double radius;
  final List<BoxShadow> shadows;
  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadows,
    ),
    child: CustomPaint(painter: _InsetPainter(radius), child: child),
  );
}

class _InsetPainter extends CustomPainter {
  const _InsetPainter(this.radius);

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.save();
    canvas.clipRRect(shape);
    for (final (offset, color, blur) in <(Offset, Color, double)>[
      (const Offset(2, 2), TidyColors.clayHighlight, 2),
      (const Offset(-3, -4), TidyColors.clayReflection, 3),
    ]) {
      final shadow = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect((Offset.zero & size).inflate(30))
        ..addRRect(shape.shift(offset));
      canvas.drawPath(
        shadow,
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InsetPainter oldDelegate) =>
      oldDelegate.radius != radius;
}
