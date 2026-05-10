import 'package:flutter/material.dart';

class TimelinePainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;
  final Color color;

  TimelinePainter({
    required this.isFirst,
    required this.isLast,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey
          .withValues(alpha: 0.3) // 淺灰色實線
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double dotRadius = 4.0;
    final double centerX = size.width / 2;
    // 將圓點放在正中間
    final double dotY = size.height / 2;

    // 先畫實心圓點
    canvas.drawCircle(Offset(centerX, dotY), dotRadius, dotPaint);

    // 圓點的排斥區（實線在此區間斷開，留出一點空隙顯示圓點）
    final double exclTop = dotY - dotRadius - 4.0;
    final double exclBottom = dotY + dotRadius + 4.0;

    // 畫上半部實線
    if (exclTop > 0) {
      canvas.drawLine(Offset(centerX, 0), Offset(centerX, exclTop), linePaint);
    }

    // 畫下半部實線 (如果是最後一項則不畫到底部)
    if (!isLast && exclBottom < size.height) {
      canvas.drawLine(
        Offset(centerX, exclBottom),
        Offset(centerX, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) {
    return oldDelegate.isFirst != isFirst ||
        oldDelegate.isLast != isLast ||
        oldDelegate.color != color;
  }
}
