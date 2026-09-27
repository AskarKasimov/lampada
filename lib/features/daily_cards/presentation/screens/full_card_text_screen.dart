import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/fullscreen_swipe_dismiss.dart';
import '../../domain/entities/day_card.dart';
import '../widgets/card_content.dart';

/// Переход разворачивает короткое превью в пространство для полного текста.
/// Обратная анимация такая же, поэтому закрытие ощущается возвращением к
/// карточке, а не сменой несвязанного экрана.
class FullCardTextRoute extends PageRoute<void> {
  FullCardTextRoute({
    required this.card,
    this.showSourceDash = true,
    this.showSource = true,
  });

  final DayCard card;
  final bool showSourceDash;
  final bool showSource;

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
  ) => FullCardTextScreen(
    card: card,
    showSourceDash: showSourceDash,
    showSource: showSource,
  );

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
    this.showSource = true,
    super.key,
  });

  final DayCard card;
  final bool showSourceDash;
  final bool showSource;

  @override
  State<FullCardTextScreen> createState() => _FullCardTextScreenState();
}

class _FullCardTextScreenState extends State<FullCardTextScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FullscreenSwipeDismiss(child: _screen(context));

  Widget _screen(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Scaffold(
      body: SafeArea(
        left: false,
        right: false,
        child: Stack(
          children: [
            Padding(
              // Полный текст продолжает сетку превью, чтобы раскрытие не
              // сдвигало строку и крестик относительно карточки.
              padding: AppSpacing.of(context).readerPadding,
              child: CardContent(
                card: widget.card,
                showBadge: false,
                showSourceDash: widget.showSourceDash,
                showSource: widget.showSource,
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
    );
  }
}
