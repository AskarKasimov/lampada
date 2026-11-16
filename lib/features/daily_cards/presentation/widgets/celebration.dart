import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Блок проявляется и всплывает на своё место.
class CelebrationRise extends StatelessWidget {
  const CelebrationRise({
    required this.animation,
    required this.child,
    this.enabled = true,
    super.key,
  });

  final Animation<double> animation;
  final Widget child;

  /// Пока блок не показан, он не принимает нажатия: прозрачная кнопка
  /// иначе срабатывала бы от случайного тапа.
  final bool enabled;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !enabled,
    child: AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - animation.value)),
          child: child,
        ),
      ),
      child: child,
    ),
  );
}

/// Печать «прочитано»: выпрыгивает с отскоком, от неё расходятся кольцо
/// света и искры, как от затеплённой лампады.
class CelebrationSeal extends StatelessWidget {
  const CelebrationSeal({
    required this.pop,
    required this.burst,
    required this.colors,
    super.key,
  });

  final Animation<double> pop;
  final Animation<double> burst;
  final AppColorsExtension colors;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 72,
    child: CustomPaint(
      painter: _SparkBurstPainter(
        progress: burst,
        spark: colors.flameLight,
        glow: colors.accent,
      ),
      child: ScaleTransition(
        scale: pop,
        child: RotationTransition(
          turns: Tween(begin: -0.12, end: 0.0).animate(pop),
          child: Icon(
            CupertinoIcons.checkmark_seal_fill,
            size: 64,
            color: colors.accent,
          ),
        ),
      ),
    ),
  );
}

class _SparkBurstPainter extends CustomPainter {
  _SparkBurstPainter({
    required this.progress,
    required this.spark,
    required this.glow,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color spark;
  final Color glow;

  static const _sparks = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;
    final center = size.center(Offset.zero);
    final fade = 1 - t;
    final out = Curves.easeOutCubic.transform(t);

    canvas.drawCircle(
      center,
      lerpDouble(30, 110, out)!,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * fade
        ..color = glow.withValues(alpha: 0.45 * fade),
    );

    final paint = Paint();
    for (var i = 0; i < _sparks; i++) {
      // Разброс детерминированный: каждая вспышка одинаковая, без рандома.
      final angle = i * 2 * math.pi / _sparks + (i.isEven ? 0.13 : -0.09);
      final reach = 78.0 + (i % 3) * 22;
      final distance = lerpDouble(26, reach, out)!;
      final radius = (3.2 - (i % 3) * 0.7) * (1 - t * 0.5);
      final offset =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      paint.color = (i % 4 == 0 ? glow : spark).withValues(alpha: fade);
      canvas.drawCircle(offset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SparkBurstPainter oldDelegate) =>
      oldDelegate.spark != spark || oldDelegate.glow != glow;
}
