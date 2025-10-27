import 'package:flutter/material.dart';

class NeonHomeIconPainter extends CustomPainter {
  final Color color;
  final double blurSigma;

  NeonHomeIconPainter({
    required this.color,
    this.blurSigma = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final housePath = Path();
    housePath.moveTo(size.width * 0.05, size.height * 0.5);
    housePath.lineTo(size.width * 0.05, size.height * 0.95);
    housePath.lineTo(size.width * 0.95, size.height * 0.95);
    housePath.lineTo(size.width * 0.95, size.height * 0.5);
    housePath.lineTo(size.width * 0.5, size.height * 0.05);
    housePath.lineTo(size.width * 0.05, size.height * 0.5);
    housePath.moveTo(size.width * 0.7, size.height * 0.28);
    housePath.lineTo(size.width * 0.7, size.height * 0.1);
    housePath.lineTo(size.width * 0.85, size.height * 0.1);
    housePath.lineTo(size.width * 0.85, size.height * 0.37);

    final doorPath = Path();
    doorPath.moveTo(size.width * 0.35, size.height * 0.95);
    doorPath.lineTo(size.width * 0.35, size.height * 0.7);
    doorPath.lineTo(size.width * 0.65, size.height * 0.7);
    doorPath.lineTo(size.width * 0.65, size.height * 0.95);

    canvas.drawPath(housePath, glowPaint);
    canvas.drawPath(doorPath, glowPaint);

    canvas.drawPath(housePath, linePaint);
    canvas.drawPath(doorPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant NeonHomeIconPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.blurSigma != blurSigma;
  }
}
