import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'lamp_level.dart';

/// Свет от лампады, заполняющий сцену снизу вверх. Кладётся самым нижним слоем
/// стека — под киот и контент.
class LampGlow extends StatefulWidget {
  const LampGlow({
    super.key,
    required this.level,
    this.center = const Alignment(0, 0.82),
  });

  final LampLevel level;

  /// Центр свечения — точка чаши лампады.
  final Alignment center;

  @override
  State<LampGlow> createState() => _LampGlowState();
}

class _LampGlowState extends State<LampGlow>
    with SingleTickerProviderStateMixin {
  /// 4 с — ленивое дыхание отсвета. Некратно 1.2 с дрожания огонька
  /// (`LampadaMark`): кратные периоды сложились бы в общий пульс, и сцена
  /// читалась бы как дышащий уведомлятор — ровно тот геймифицированный тон,
  /// от которого уходили.
  ///
  /// Создаётся в [initState], а не ленивым инициализатором поля: при
  /// [LampLevel.unlit] сборка выходит первой строкой и до контроллера не
  /// дотрагивается, поэтому ленивое поле впервые инициализировалось бы прямо
  /// в [dispose] — а там `AnimationController` уже не может дотянуться до
  /// `TickerMode` в снятом дереве и роняет экран.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
  }

  /// Доля кратчайшей стороны, до которой достаёт свет.
  double get _radius => switch (widget.level) {
        LampLevel.unlit => 0.0,
        LampLevel.kindled => 0.38,
        LampLevel.steady => 0.62,
        LampLevel.full => 0.95,
      };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.level.isLit) return const SizedBox.shrink();

    final colors = AppColorsExtension.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Раздельные значения, а не общая формула: на тёмном фоне тот же alpha
    // засветил бы экран, на светлом — не был бы виден вовсе.
    final peak = isDark ? 0.20 : 0.34;

    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // Амплитуда в единицы процентов: дыхание должно ощущаться, но не
            // замечаться.
            final breath =
                1.0 + 0.04 * Curves.easeInOut.transform(_controller.value);
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: widget.center,
                  radius: _radius * breath,
                  // Мягкость — четырьмя стопами с падающей альфой. Это замена
                  // блюру, а не его приближение: блюр здесь запрещён.
                  colors: [
                    colors.flameLight.withValues(alpha: peak),
                    colors.accent.withValues(alpha: peak * 0.55),
                    colors.accent.withValues(alpha: peak * 0.18),
                    colors.accent.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.35, 0.68, 1.0],
                ),
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}
