import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Знакомство с разделом: плашка проявляется на своём месте над текстом
/// чуть крупнее обычного, держится, пока её прочтут, и пружиной садится в
/// обычный размер. Текст карточки всё это время на месте.
///
/// Пружина почти критически задемпфирована: плашка садится без желейной
/// дрожи, лишь едва заметно дотягиваясь.
class SectionIntroMotion {
  const SectionIntroMotion({
    this.bigScale = 1.5,
    this.appear = 0.3,
    this.returnStart = 0.9,
    this.springHz = 1.8,
    this.springDamping = 0.85,
  });

  /// Во сколько раз плашка крупнее обычной в начале.
  final double bigScale;

  /// Сколько секунд плашка проявляется и когда начинает уменьшаться.
  final double appear;
  final double returnStart;

  final double springHz;
  final double springDamping;

  /// Когда отклонение пружины меньше этого, плашка считается на месте.
  static const _rest = 0.002;

  double get _omega => 2 * math.pi * springHz;

  double get duration {
    final amplitude = 1 / math.sqrt(1 - springDamping * springDamping);
    return returnStart + math.log(amplitude / _rest) / (springDamping * _omega);
  }

  ({double opacity, double scale}) at(double seconds) {
    if (seconds >= duration) return (opacity: 1, scale: 1);
    if (seconds < returnStart) {
      final shown = Curves.easeOutCubic.transform(
        (seconds / appear).clamp(0.0, 1.0),
      );
      // Проявляясь, плашка чуть дорастает до крупного размера.
      return (opacity: shown, scale: bigScale - 0.1 * (1 - shown));
    }
    final t = seconds - returnStart;
    final damped = math.sqrt(1 - springDamping * springDamping);
    final settled =
        1 -
        math.exp(-springDamping * _omega * t) *
            (math.cos(_omega * damped * t) +
                springDamping / damped * math.sin(_omega * damped * t));
    return (opacity: 1, scale: 1 + (bigScale - 1) * (1 - settled));
  }
}

/// Плашка раздела, которая при [playing] разыгрывает [SectionIntroMotion]
/// по [controller]: его значение 0…1 — доля [SectionIntroMotion.duration].
class SectionPillIntro extends StatelessWidget {
  const SectionPillIntro({
    required this.controller,
    required this.playing,
    required this.child,
    this.motion = const SectionIntroMotion(),
    super.key,
  });

  final Animation<double> controller;
  final bool playing;
  final SectionIntroMotion motion;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    child: child,
    builder: (context, child) {
      final pose = playing
          ? motion.at(controller.value * motion.duration)
          : (opacity: 1.0, scale: 1.0);
      return Opacity(
        opacity: pose.opacity,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(pose.scale, pose.scale, 1),
          child: child,
        ),
      );
    },
  );
}
