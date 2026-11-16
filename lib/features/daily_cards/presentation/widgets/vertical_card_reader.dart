import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/reading_action_space.dart';
import 'rail_scrubber.dart';

/// Общая TikTok-подобная рамка читалок карточек и курса.
///
/// Текст внутри страницы не участвует в вертикальном жесте: если он длинный,
/// читалка открывает его отдельно. Так свайп всегда переключает карточку.
class VerticalCardReader extends StatelessWidget {
  const VerticalCardReader({
    required this.controller,
    required this.itemCount,
    required this.onPageChanged,
    required this.itemBuilder,
    required this.header,
    required this.leftRail,
    required this.actions,
    required this.onClose,
    required this.closeColor,
    this.headerInteractive = false,
    this.closeOnRight,
    this.closeTooltip,
    this.showExit = true,
    this.topLeftAction,
    this.topRightAction,
    this.reverse = false,
    super.key,
  });

  // Полный материал примеряем с двумя действиями. Только превью резервирует
  // третью кнопку: это исключает зависимость решения от текущей панели.
  static const _actionsHeight = 2 * 56.0 + 4.0;
  static const _fullTextActionHeight = 56.0 + 4.0;
  static const _actionsBottom = 28.0;
  static const _textActionsGap = 16.0;

  final PageController controller;
  final int itemCount;
  final ValueChanged<int> onPageChanged;
  final IndexedWidgetBuilder itemBuilder;
  final Widget header;

  /// Обычно плашка шапки только подпись, и касания проходят к странице.
  /// Курс делает её кнопкой оглавления.
  final bool headerInteractive;
  final Widget leftRail;
  final Widget actions;
  final VoidCallback onClose;
  final Color closeColor;

  /// Defaults to a right-side close on fullscreen dialogs and left-side back
  /// on ordinary pushed routes.
  final bool? closeOnRight;
  final String? closeTooltip;
  final bool showExit;
  final Widget? topLeftAction;
  final Widget? topRightAction;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    final exitsOnRight = closeOnRight ?? _isDialog(context);
    // Крестик остаётся доступен, даже если действие задано в том же слоте.
    final leftActionTop = showExit && !exitsOnRight && topLeftAction != null
        ? 48.0
        : 0.0;
    final rightActionTop = showExit && exitsOnRight && topRightAction != null
        ? 48.0
        : 0.0;
    return SafeArea(
      left: false,
      right: false,
      child: Stack(
        children: [
          Padding(
            // Дополнительное поле слева оставляет место панели прогресса.
            padding: AppSpacing.of(context).readerPadding,
            child: PageView.builder(
              controller: controller,
              scrollDirection: Axis.vertical,
              reverse: reverse,
              itemCount: itemCount,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) => ReadingActionSpace(
                previewExtraInset: _fullTextActionHeight,
                bottomInset:
                    (_actionsBottom +
                            _actionsHeight +
                            _textActionsGap -
                            AppSpacing.of(context).readerPadding.bottom)
                        .clamp(0.0, double.infinity),
                child: itemBuilder(context, index),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 76,
            right: 76,
            child: IgnorePointer(
              ignoring: !headerInteractive,
              child: Center(child: header),
            ),
          ),
          // Колонка шире самих точек: по ней листают пальцем
          // ([RailScrubber]). Точки по-прежнему в 16 pt от края.
          Positioned(
            top: 64,
            bottom: 64,
            left: 0,
            width: RailScrubber.hitWidth,
            child: Center(child: leftRail),
          ),
          Positioned(right: 12, bottom: _actionsBottom, child: actions),
          if (showExit)
            Positioned(
              top: 0,
              left: exitsOnRight ? null : 0,
              right: exitsOnRight ? 0 : null,
              child: _closeButton(context),
            ),
          if (topLeftAction != null)
            Positioned(top: leftActionTop, left: 0, child: topLeftAction!),
          if (topRightAction != null)
            Positioned(top: rightActionTop, right: 0, child: topRightAction!),
        ],
      ),
    );
  }

  /// Экран, выехавший снизу, закрывается крестиком, как AppBar такого
  /// маршрута; открытый вбок уходит стрелкой назад.
  Widget _closeButton(BuildContext context) {
    final isDialog = _isDialog(context);
    return IconButton(
      onPressed: onClose,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      padding: EdgeInsets.zero,
      icon: Icon(
        (closeOnRight ?? isDialog)
            ? CupertinoIcons.xmark
            : CupertinoIcons.arrow_left,
        size: 22,
        color: closeColor,
      ),
      tooltip:
          closeTooltip ?? ((closeOnRight ?? isDialog) ? 'Закрыть' : 'Назад'),
    );
  }

  bool _isDialog(BuildContext context) =>
      ModalRoute.of(context)?.fullscreenDialog ?? false;
}

/// Единый крупный формат действий в правой панели читалки.
class ReaderActionButton extends StatelessWidget {
  const ReaderActionButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    required this.color,
    super.key,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    constraints: const BoxConstraints.tightFor(width: 56, height: 56),
    padding: EdgeInsets.zero,
    icon: Icon(icon, size: 28, color: color),
  );
}
