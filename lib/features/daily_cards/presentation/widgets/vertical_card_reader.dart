import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

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
    this.reverse = false,
    super.key,
  });

  final PageController controller;
  final int itemCount;
  final ValueChanged<int> onPageChanged;
  final IndexedWidgetBuilder itemBuilder;
  final Widget header;
  final Widget leftRail;
  final Widget actions;
  final VoidCallback onClose;
  final Color closeColor;
  final bool reverse;

  @override
  Widget build(BuildContext context) => SafeArea(
    left: false,
    right: false,
    child: Stack(
      children: [
        Padding(
          // Текст продолжает линию карточки на «Сегодня»: 20px поля и 13px
          // под метку непрочитанного.
          padding: const EdgeInsets.fromLTRB(33, 48, 24, 24),
          child: PageView.builder(
            controller: controller,
            scrollDirection: Axis.vertical,
            reverse: reverse,
            itemCount: itemCount,
            onPageChanged: onPageChanged,
            itemBuilder: itemBuilder,
          ),
        ),
        Positioned(
          top: 8,
          left: 76,
          right: 76,
          child: IgnorePointer(child: Center(child: header)),
        ),
        Positioned(
          top: 64,
          bottom: 64,
          left: 12,
          child: Center(child: leftRail),
        ),
        Positioned(right: 12, bottom: 28, child: actions),
        Positioned(
          top: 0,
          left: 0,
          child: IconButton(
            onPressed: onClose,
            icon: Icon(CupertinoIcons.arrow_left, size: 22, color: closeColor),
            tooltip: 'Назад',
          ),
        ),
      ],
    ),
  );
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
