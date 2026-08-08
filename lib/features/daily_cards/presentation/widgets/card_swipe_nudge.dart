import 'package:flutter/material.dart';

const _nudgeDistance = 24.0;

/// После показа экрана один раз плавно качает карточку в сторону свайпа.
class CardSwipeNudge extends StatefulWidget {
  const CardSwipeNudge({required this.child, super.key});

  final Widget child;

  @override
  State<CardSwipeNudge> createState() => _CardSwipeNudgeState();
}

class _CardSwipeNudgeState extends State<CardSwipeNudge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 900),
    vsync: this,
  );
  late final Animation<double> _offset = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: -_nudgeDistance,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: -_nudgeDistance,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 2,
    ),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _offset,
    child: widget.child,
    builder: (context, child) =>
        Transform.translate(offset: Offset(_offset.value, 0), child: child),
  );
}
