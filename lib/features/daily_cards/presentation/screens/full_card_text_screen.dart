import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/day_card.dart';
import '../widgets/card_content.dart';

/// Переход разворачивает короткое превью в пространство для полного текста.
/// Обратная анимация такая же, поэтому закрытие ощущается возвращением к
/// карточке, а не сменой несвязанного экрана.
class FullCardTextRoute extends PageRoute<void> {
  FullCardTextRoute({required this.card, this.showSourceDash = true});

  final DayCard card;
  final bool showSourceDash;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 280);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 220);

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => FullCardTextScreen(card: card, showSourceDash: showSourceDash);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(curve),
      child: ScaleTransition(
        alignment: Alignment.center,
        scale: Tween<double>(begin: 0.88, end: 1).animate(curve),
        child: child,
      ),
    );
  }
}

/// Полный текст одной карточки: здесь вертикальный жест прокручивает только
/// материал, а не переключает страницы основной читалки.
class FullCardTextScreen extends StatefulWidget {
  const FullCardTextScreen({
    required this.card,
    this.showSourceDash = true,
    super.key,
  });

  final DayCard card;
  final bool showSourceDash;

  @override
  State<FullCardTextScreen> createState() => _FullCardTextScreenState();
}

class _FullCardTextScreenState extends State<FullCardTextScreen>
    with SingleTickerProviderStateMixin {
  static const _dismissDistance = 112.0;
  final _scrollController = ScrollController();
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
    _scrollController.dispose();
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
    child: _screen(context),
  );

  Widget _screen(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Scaffold(
      body: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        child: SafeArea(
          left: false,
          right: false,
          child: Stack(
            children: [
              Padding(
                // Полный текст продолжает сетку превью, чтобы раскрытие не
                // сдвигало строку и крестик относительно карточки.
                padding: const EdgeInsets.fromLTRB(33, 48, 24, 24),
                child: CardContent(
                  card: widget.card,
                  showBadge: false,
                  showSourceDash: widget.showSourceDash,
                  scrollController: _scrollController,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    CupertinoIcons.xmark,
                    size: 22,
                    color: colors.homeSubtitle,
                  ),
                  tooltip: 'Закрыть полный текст',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
