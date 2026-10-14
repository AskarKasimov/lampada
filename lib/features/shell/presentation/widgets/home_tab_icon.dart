import 'package:flutter/material.dart';

/// Иконка вкладки «Главная»: дом с крестом на коньке.
///
/// Своя, а не из Cupertino: подходящего знака там нет, а закат на месте
/// главной ничего не говорил. Рисуется в сетке 24×24 с толщиной линии,
/// близкой к контурным иконкам Cupertino рядом.
///
/// Залитый вариант строится из контурного: те же линии плюс заливка дома,
/// из которой вырезана дверь. Так у двух вариантов не расходятся детали:
/// пол под дверью прерывается в обоих.
class HomeTabIcon extends StatelessWidget {
  const HomeTabIcon({
    required this.filled,
    required this.color,
    this.size = 20,
    super.key,
  });

  /// Залитый вариант для активной вкладки, контурный для остальных.
  final bool filled;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _HomeTabIconPainter(filled: filled, color: color),
    ),
  );
}

class _HomeTabIconPainter extends CustomPainter {
  const _HomeTabIconPainter({required this.filled, required this.color});

  final bool filled;
  final Color color;

  static const _grid = 24.0;
  static const _stroke = 1.6;

  /// Крест на коньке.
  static final _cross = Path()
    ..moveTo(12, 1.4)
    ..lineTo(12, 4.8)
    ..moveTo(10.7, 2.6)
    ..lineTo(13.3, 2.6);

  /// Скат крыши с выступами за стены.
  static final _roof = Path()
    ..moveTo(4, 11.4)
    ..lineTo(12, 5)
    ..lineTo(20, 11.4);

  /// Стены и пол одной линией; на месте двери пол прерывается аркой.
  static final _walls = Path()
    ..moveTo(6, 9.8)
    ..lineTo(6, 20.4)
    ..lineTo(10, 20.4)
    ..lineTo(10, 16.6)
    ..arcToPoint(const Offset(14, 16.6), radius: const Radius.circular(2))
    ..lineTo(14, 20.4)
    ..lineTo(18, 20.4)
    ..lineTo(18, 9.8);

  /// Внутренность дома под крышей без проёма двери.
  static final _body = Path.combine(
    PathOperation.difference,
    Path()
      ..moveTo(12, 5)
      ..lineTo(18, 9.8)
      ..lineTo(18, 20.4)
      ..lineTo(6, 20.4)
      ..lineTo(6, 9.8)
      ..close(),
    Path()
      ..moveTo(10, 20.4)
      ..lineTo(10, 16.6)
      ..arcToPoint(const Offset(14, 16.6), radius: const Radius.circular(2))
      ..lineTo(14, 20.4)
      ..close(),
  );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _grid, size.height / _grid);
    if (filled) {
      canvas.drawPath(_body, Paint()..color = color);
    }
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawPath(_cross, line)
      ..drawPath(_roof, line)
      ..drawPath(_walls, line);
  }

  @override
  bool shouldRepaint(_HomeTabIconPainter oldDelegate) =>
      oldDelegate.filled != filled || oldDelegate.color != color;
}
