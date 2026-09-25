import 'package:flutter/material.dart';

enum TidyGlyphName {
  storage,
  photo,
  video,
  shield,
  contacts,
  lock,
  spark,
  check,
  trash,
  back,
}

class TidyGlyph extends StatelessWidget {
  const TidyGlyph(this.name, {this.size = 24, this.color, super.key});

  final TidyGlyphName name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GlyphPainter(name, color ?? IconTheme.of(context).color!),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.name, this.color);

  final TidyGlyphName name;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Path path = Path();
    switch (name) {
      case TidyGlyphName.storage:
        path.moveTo(4, 6);
        path.lineTo(20, 6);
        path.lineTo(22, 19);
        path.lineTo(2, 19);
        path.close();
        path.moveTo(4, 6);
        path.lineTo(7, 3);
        path.lineTo(17, 3);
        path.lineTo(20, 6);
        path.moveTo(3, 14);
        path.lineTo(9, 14);
        path.lineTo(10, 17);
        path.lineTo(14, 17);
        path.lineTo(15, 14);
        path.lineTo(21, 14);
      case TidyGlyphName.photo:
        path.addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 3, 18, 18),
            const Radius.circular(1),
          ),
        );
        path.moveTo(3, 17);
        path.lineTo(9, 11);
        path.lineTo(13, 15);
        path.lineTo(16, 12);
        path.lineTo(21, 17);
        path.addOval(Rect.fromCircle(center: const Offset(15, 7), radius: 0.1));
      case TidyGlyphName.video:
        path.addRect(const Rect.fromLTWH(4, 5, 16, 14));
        path.moveTo(10, 9);
        path.lineTo(15, 12);
        path.lineTo(10, 15);
        path.close();
      case TidyGlyphName.shield:
        path.moveTo(12, 3);
        path.lineTo(3, 7);
        path.lineTo(3, 12);
        path.cubicTo(3, 17, 12, 21, 12, 21);
        path.cubicTo(12, 21, 21, 17, 21, 12);
        path.lineTo(21, 7);
        path.close();
        path.moveTo(8, 12);
        path.lineTo(11, 15);
        path.lineTo(16, 9);
      case TidyGlyphName.contacts:
        path.moveTo(8, 3);
        path.lineTo(19, 3);
        path.lineTo(19, 21);
        path.lineTo(5, 21);
        path.lineTo(5, 3);
        path.moveTo(2, 7);
        path.lineTo(6, 7);
        path.moveTo(2, 12);
        path.lineTo(6, 12);
        path.moveTo(2, 17);
        path.lineTo(6, 17);
        path.addOval(Rect.fromCircle(center: const Offset(12, 9), radius: 2));
        path.moveTo(8, 17);
        path.cubicTo(8, 13, 16, 13, 16, 17);
      case TidyGlyphName.lock:
        path.addRect(const Rect.fromLTWH(6, 10, 12, 11));
        path.moveTo(8, 10);
        path.lineTo(8, 7);
        path.cubicTo(8, 1.7, 16, 1.7, 16, 7);
        path.lineTo(16, 10);
        path.moveTo(12, 14);
        path.lineTo(12, 17);
      case TidyGlyphName.spark:
        path.moveTo(12, 2);
        path.lineTo(14.5, 9.5);
        path.lineTo(22, 12);
        path.lineTo(14.5, 14.5);
        path.lineTo(12, 22);
        path.lineTo(9.5, 14.5);
        path.lineTo(2, 12);
        path.lineTo(9.5, 9.5);
        path.close();
      case TidyGlyphName.check:
        path.moveTo(5, 12);
        path.lineTo(9, 16);
        path.lineTo(19, 6);
      case TidyGlyphName.trash:
        path.moveTo(4, 6);
        path.lineTo(20, 6);
        path.moveTo(9, 6);
        path.lineTo(10, 3);
        path.lineTo(14, 3);
        path.lineTo(15, 6);
        path.moveTo(6, 8);
        path.lineTo(7, 21);
        path.lineTo(17, 21);
        path.lineTo(18, 8);
        path.moveTo(10, 11);
        path.lineTo(10.5, 18);
        path.moveTo(14, 11);
        path.lineTo(13.5, 18);
      case TidyGlyphName.back:
        path.moveTo(14, 5);
        path.lineTo(7, 12);
        path.lineTo(14, 19);
    }
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.name != name || oldDelegate.color != color;
}
