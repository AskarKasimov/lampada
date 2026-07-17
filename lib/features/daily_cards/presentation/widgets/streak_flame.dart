import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Тлеющий огонёк лампадки — тихий фоновый индикатор серии, не KPI.
/// Плавно пульсирует, не привлекая лишнего внимания.
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
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [AppColors.flameLight, AppColors.accent],
            stops: [0.0, 0.7],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.55),
              blurRadius: widget.size * 0.8,
            ),
          ],
        ),
      ),
    );
  }
}
