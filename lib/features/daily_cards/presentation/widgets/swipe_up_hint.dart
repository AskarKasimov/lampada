import 'package:flutter/material.dart';

/// Палец поверх карточки дважды проводит снизу вверх: так новичок видит,
/// что ленту листают свайпом. Текст при этом стоит на месте.
///
/// Каждый проход: палец проявляется, касается (чуть приседает), ведёт вверх
/// с разгоном и торможением и гаснет у верхней точки.
class SwipeUpHint extends StatefulWidget {
  const SwipeUpHint({required this.color, required this.onDone, super.key});

  final Color color;

  /// Подсказка доиграла; родитель убирает её.
  final VoidCallback onDone;

  static const _strokes = 2;
  static const _stroke = Duration(milliseconds: 1300);
  static const _travel = 56.0;

  @override
  State<SwipeUpHint> createState() => _SwipeUpHintState();
}

class _SwipeUpHintState extends State<SwipeUpHint>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: SwipeUpHint._stroke * SwipeUpHint._strokes,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().then((_) {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Положение внутри одного прохода [t] 0…1.
  ({double opacity, double rise, double press}) _pose(double t) {
    double phase(double from, double to) =>
        ((t - from) / (to - from)).clamp(0.0, 1.0);
    final appear = Curves.easeOut.transform(phase(0, 0.15));
    final fade = Curves.easeIn.transform(phase(0.75, 0.95));
    // Касание: палец чуть уменьшается, будто прижался к стеклу.
    final press = Curves.easeOut.transform(phase(0.15, 0.25));
    final rise = Curves.easeInOutCubic.transform(phase(0.25, 0.85));
    return (opacity: appear * (1 - fade), rise: rise, press: press);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      final t = (_controller.value * SwipeUpHint._strokes) % 1;
      final pose = _pose(_controller.isCompleted ? 1 : t);
      return Opacity(
        opacity: pose.opacity,
        child: Transform.translate(
          offset: Offset(0, -SwipeUpHint._travel * pose.rise),
          child: Transform.scale(scale: 1 - 0.08 * pose.press, child: child),
        ),
      );
    },
    child: ExcludeSemantics(
      child: Icon(Icons.swipe_vertical_outlined, size: 64, color: widget.color),
    ),
  );
}
