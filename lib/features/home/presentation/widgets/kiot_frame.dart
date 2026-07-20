import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Арка киота — обвод сцены красного угла. Килевидная, а не полукруглая:
/// полукруг читается как обобщённо-храмовый, килевидный опознаётся как русский.
///
/// Стойки книзу не замыкаются: рамка обязана ощущаться обводом сцены, а не
/// границей контейнера.
class KiotFrame extends StatelessWidget {
  const KiotFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _KiotPainter(line: AppColorsExtension.of(context).kiotLine),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _KiotPainter extends CustomPainter {
  const _KiotPainter({required this.line});

  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Пята арки: ниже неё стойки идут вертикально.
    final springY = h * 0.30;
    final tipY = h * 0.02;
    final bottomY = h * 0.92;

    final path = Path()
      ..moveTo(0, bottomY)
      ..lineTo(0, springY)
      // Левая ветвь: от пяты выгибается наружу, потом сходится к острию.
      ..cubicTo(0, springY * 0.42, cx * 0.52, tipY + h * 0.10, cx, tipY)
      ..cubicTo(w - cx * 0.52, tipY + h * 0.10, w, springY * 0.42, w, springY)
      ..lineTo(w, bottomY);

    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_KiotPainter old) => old.line != line;
}
