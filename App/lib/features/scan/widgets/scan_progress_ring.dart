import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';

class ScanProgressRing extends StatelessWidget {
  const ScanProgressRing({required this.progress, super.key});

  final double? progress;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 210,
    height: 210,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.expand(
          child: progress == null
              ? const CircularProgressIndicator(
                  strokeWidth: 18,
                  backgroundColor: TidyColors.violetTint,
                  valueColor: AlwaysStoppedAnimation(TidyColors.primary),
                )
              : CustomPaint(
                  painter: _ProgressRingPainter(progress!.clamp(0.0, 1.0)),
                ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              progress == null
                  ? 'Scanning'
                  : '${(progress! * 100).clamp(0, 100).round()}%',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: progress == null ? 28 : 44,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'of accessible items',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ],
    ),
  );
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    const startAngle = -math.pi;
    const strokeWidth = 18.0;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = TidyColors.violetTint;
    canvas.drawArc(rect, 0, 2 * 3.141592653589793, false, track);
    if (progress == 0) return;
    final sweepAngle = 2 * math.pi * progress;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [TidyColors.lightViolet, TidyColors.primary, TidyColors.pink],
        stops: [0, .78 * progress, progress],
        transform: const GradientRotation(math.pi),
      ).createShader(rect);
    canvas.drawArc(rect, startAngle, sweepAngle, false, arc);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
