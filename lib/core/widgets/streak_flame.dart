import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Тлеющий огонёк лампадки — тихий индикатор серии (не KPI), плавно пульсирует.
class StreakFlame extends StatefulWidget {
  const StreakFlame({super.key, this.size = 10});

  final double size;

  @override
  State<StreakFlame> createState() => _StreakFlameState();
}

class _StreakFlameState extends State<StreakFlame>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Пульсация — единственная незатухающая анимация в приложении, и она
  /// живёт на главном экране. При включённом Reduce Motion огонёк просто
  /// горит ровно: образ сохраняется, движения нет.
  void _syncWithMotionPreference(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1;
    } else if (!reduce && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncWithMotionPreference(context);
    final colors = AppColorsExtension.of(context);
    return FadeTransition(
      opacity: Tween(
        begin: 0.85,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: [colors.flameLight, colors.accent],
            stops: const [0.0, 0.7],
          ),
          boxShadow: [
            BoxShadow(
              color: colors.accent.withValues(alpha: 0.55),
              blurRadius: widget.size * 0.8,
            ),
          ],
        ),
      ),
    );
  }
}
