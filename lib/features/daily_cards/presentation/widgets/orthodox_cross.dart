import 'package:flutter/material.dart';

/// Восьмиконечный православный крест контуром, в толщину линий системных
/// значков. В наборах иконок такого креста нет, поэтому он нарисован.
class OrthodoxCross extends StatelessWidget {
  const OrthodoxCross({required this.color, this.size = 150, super.key});

  final Color color;
  final double size;

  /// Концы нижней косой перекладины. По канону она поднята концом по правую
  /// руку Спасителя, то есть левым от зрителя.
  static (Offset, Offset) footrest(Size size) => (
    Offset(size.width * 0.36, size.height * 0.67),
    Offset(size.width * 0.64, size.height * 0.78),
  );

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _OrthodoxCrossPainter(color),
  );
}

class _OrthodoxCrossPainter extends CustomPainter {
  _OrthodoxCrossPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.065
      ..strokeCap = StrokeCap.round;

    // Вертикаль, табличка, главная перекладина и косое подножие одним
    // контуром: цвет полупрозрачный, и отдельные линии темнели бы на
    // пересечениях.
    final (left, right) = OrthodoxCross.footrest(size);
    final path = Path()
      ..moveTo(w * 0.5, h * 0.08)
      ..lineTo(w * 0.5, h * 0.94)
      ..moveTo(w * 0.38, h * 0.22)
      ..lineTo(w * 0.62, h * 0.22)
      ..moveTo(w * 0.2, h * 0.38)
      ..lineTo(w * 0.8, h * 0.38)
      ..moveTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OrthodoxCrossPainter oldDelegate) =>
      color != oldDelegate.color;
}
