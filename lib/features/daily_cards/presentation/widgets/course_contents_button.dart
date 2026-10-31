import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/app_pill_badge.dart';

/// Плашка темы в шапке читалки курса: по тапу открывает оглавление.
///
/// Снаружи это та же [AppPillBadge], поэтому при первом открытии курса она
/// дважды пульсирует (`pulse`): иначе плашку не отличить от подписи.
class CourseContentsButton extends StatefulWidget {
  const CourseContentsButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.pulse = false,
    super.key,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  /// Однократная подсказка, что на плашку можно нажать.
  final bool pulse;

  @override
  State<CourseContentsButton> createState() => _CourseContentsButtonState();
}

class _CourseContentsButtonState extends State<CourseContentsButton>
    with SingleTickerProviderStateMixin {
  // Пауза, чтобы читалка успела выехать, затем два вдоха плашки.
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  late final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 400),
    for (var i = 0; i < 2; i++) ...[
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 300,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.08,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 300,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 300),
    ],
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  @override
  void didUpdateWidget(CourseContentsButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !oldWidget.pulse) _start();
  }

  void _start() {
    if (!mounted) return;
    // Системное «Уменьшение движения» подсказку не отменяет, но без анимации
    // она бесполезна: плашка останется кнопкой для скринридера и пальца.
    if (MediaQuery.disableAnimationsOf(context)) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    _controller.reset();
    HapticFeedback.lightImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final pill = AppPillBadge(
      label: widget.label,
      background: widget.background,
      foreground: widget.foreground,
      letterSpacing: 0.2,
    );
    return Semantics(
      button: true,
      label: '${widget.label}. Оглавление курса',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: ScaleTransition(scale: _scale, child: pill),
      ),
    );
  }
}
