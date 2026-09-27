import 'dart:async';

import 'package:flutter/material.dart';

/// Общая траектория закрытия полного текста и сохранённой карточки.
/// Вертикальные жесты остаются у прокрутки вложенного материала.
class FullscreenSwipeDismiss extends StatefulWidget {
  const FullscreenSwipeDismiss({required this.child, super.key});

  final Widget child;

  @override
  State<FullscreenSwipeDismiss> createState() => _FullscreenSwipeDismissState();
}

class _FullscreenSwipeDismissState extends State<FullscreenSwipeDismiss>
    with SingleTickerProviderStateMixin {
  static const _dismissDistance = 112.0;
  late final AnimationController _settleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Offset? _dragStart;
  double _dragX = 0;
  Animation<double>? _settleX;

  @override
  void dispose() {
    _settleController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    final x = _visibleX;
    _settleController.stop();
    setState(() {
      _dragStart = event.position;
      _dragX = x;
      _settleX = null;
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    final start = _dragStart;
    if (start == null) return;
    final offset = event.position - start;
    if (offset.dx.abs() <= offset.dy.abs()) return;
    setState(() => _dragX = offset.dx);
  }

  void _onPointerUp(PointerUpEvent event) {
    _dragStart = null;
    if (_dragX.abs() < _dismissDistance) {
      unawaited(_settleTo(0));
      return;
    }
    unawaited(_settleTo(_dismissTargetX(), dismiss: true));
  }

  double _dismissTargetX() {
    final size = MediaQuery.sizeOf(context);
    return _dragX.sign * size.width * 1.1;
  }

  Future<void> _settleTo(double targetX, {bool dismiss = false}) async {
    _settleX = Tween<double>(begin: _dragX, end: targetX).animate(
      CurvedAnimation(parent: _settleController, curve: Curves.easeOutCubic),
    );
    await _settleController.forward(from: 0);
    if (!mounted) return;
    if (dismiss) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _dragX = 0;
      _settleX = null;
    });
  }

  double get _visibleX => _settleX?.value ?? _dragX;

  Offset _visibleOffset(BuildContext context) {
    final x = _visibleX;
    final width = MediaQuery.sizeOf(context).width;
    // Путь повторяет жест карточки: при уходе в сторону она опускается вниз.
    return Offset(x, x * x / (width * 4));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _settleController,
    builder: (context, child) {
      final offset = _visibleOffset(context);
      final progress = (offset.dx.abs() / MediaQuery.sizeOf(context).width)
          .clamp(0.0, 0.35);
      return Transform.translate(
        offset: offset,
        child: Transform.rotate(
          angle: offset.dx / MediaQuery.sizeOf(context).width * 0.16,
          child: Transform.scale(
            scale: 1 - progress * 0.16,
            child: Opacity(opacity: 1 - progress * 0.5, child: child),
          ),
        ),
      );
    },
    child: Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      child: widget.child,
    ),
  );
}
