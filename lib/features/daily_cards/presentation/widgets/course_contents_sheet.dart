import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/day_card.dart';
import '../theme/card_type_style.dart';

/// Оглавление курса «Основы веры»: все темы по порядку. Возвращает номер
/// выбранной темы или null, если шторку закрыли.
Future<int?> showCourseContentsSheet(
  BuildContext context, {
  required List<String> titles,
  required int currentTopic,
  required Set<int> completed,
}) => showModalBottomSheet<int>(
  context: context,
  // Читалка открыта во вкладке со своим навигатором; без корневого
  // навигатора низ шторки ушёл бы под капсулу навбара.
  useRootNavigator: true,
  sheetAnimationStyle: const AnimationStyle(
    duration: AppMotion.modalEnter,
    reverseDuration: AppMotion.modalExit,
  ),
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: AppColorsExtension.of(context).background,
  builder: (_) => FractionallySizedBox(
    heightFactor: 0.85,
    child: CourseContentsSheet(
      titles: titles,
      currentTopic: currentTopic,
      completed: completed,
    ),
  ),
);

class CourseContentsSheet extends StatefulWidget {
  const CourseContentsSheet({
    required this.titles,
    required this.currentTopic,
    required this.completed,
    super.key,
  });

  /// Названия тем по порядку: индекс 0 — Тема 1.
  final List<String> titles;
  final int currentTopic;
  final Set<int> completed;

  @override
  State<CourseContentsSheet> createState() => _CourseContentsSheetState();
}

class _CourseContentsSheetState extends State<CourseContentsSheet> {
  ScrollController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Строки одной высоты (название не длиннее двух строк), поэтому к
  /// текущей теме прокручиваемся сразу, без построения всего списка.
  double _rowExtent(BuildContext context) =>
      24 + MediaQuery.textScalerOf(context).scale(_titleSize) * 1.25 * 2;

  static const _titleSize = 16.0;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final style = CardType.basics.styleFor(Theme.of(context).brightness);
    final padding = AppSpacing.of(context).horizontal;
    final extent = _rowExtent(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding + const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Основы веры', style: AppTheme.cardTitleStyle(context)),
              const SizedBox(height: 3),
              Text(
                'Пройдено ${widget.completed.length} '
                'из ${widget.titles.length}',
                style: AppTheme.cardCaptionStyle(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bottomInset = MediaQuery.paddingOf(context).bottom;
              // Текущая тема на третьей строке: видно, откуда юзер пришёл.
              final maxOffset = math.max(
                0.0,
                extent * widget.titles.length +
                    bottomInset -
                    constraints.maxHeight,
              );
              _controller ??= ScrollController(
                initialScrollOffset: (extent * (widget.currentTopic - 3)).clamp(
                  0.0,
                  maxOffset,
                ),
              );
              return ListView.builder(
                controller: _controller,
                itemExtent: extent,
                padding: EdgeInsets.only(bottom: bottomInset),
                itemCount: widget.titles.length,
                itemBuilder: (context, index) {
                  final number = index + 1;
                  final isCurrent = number == widget.currentTopic;
                  final isDone = widget.completed.contains(number);
                  final state = isCurrent
                      ? '. Сейчас'
                      : isDone
                      ? '. Пройдена'
                      : '';
                  return Semantics(
                    button: true,
                    excludeSemantics: true,
                    label: 'Тема $number. ${widget.titles[index]}$state',
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(number),
                      child: Container(
                        color: isCurrent ? style.tagBackground : null,
                        padding: padding,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                '$number',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isCurrent
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isCurrent
                                      ? style.tagForeground
                                      : colors.textTertiary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                widget.titles[index],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: _titleSize,
                                  height: 1.25,
                                  color: isCurrent
                                      ? style.tagForeground
                                      : colors.ink,
                                ),
                              ),
                            ),
                            if (isDone)
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Icon(
                                  CupertinoIcons.checkmark_alt,
                                  size: 18,
                                  color: style.accent,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
