import 'dart:math';
import 'package:flutter/material.dart';

class DaireselGrafik extends CustomPainter {
  final double percentage;
  final Color color;
  final double stroke;

  DaireselGrafik(this.percentage, this.color, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - stroke / 2;

    paint.color = Colors.grey.shade300;
    canvas.drawCircle(center, radius, paint);

    paint.color = color;
    double sweep = 2 * pi * percentage;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant DaireselGrafik oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}
