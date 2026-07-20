import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_pill_badge.dart';
import '../../../daily_cards/domain/entities/day_card.dart';
import '../../../daily_cards/presentation/theme/card_type_style.dart';

/// Ряд чипов «Сегодня»: прочитанный тип — в цвете, непрочитанный — контур.
class TodayStatusChips extends StatelessWidget {
  const TodayStatusChips({
    super.key,
    required this.cards,
    required this.readTypes,
  });

  final List<DayCard> cards;
  final Set<CardType> readTypes;

  /// При 5 типах карточек естественный перенос `Wrap` кладёт 4 в первую
  /// строку и одну — «Чтение» — сиротой во вторую, вразнобой. Делим сами:
  /// первой строке достаётся большая половина, остаток — второй. Полагаться
  /// на перенос по ширине нельзя — он зависит от масштаба шрифта и экрана.
  @override
  Widget build(BuildContext context) {
    if (cards.length <= 4) return _row(context, cards);

    final firstRowSize = (cards.length / 2).ceil();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row(context, cards.take(firstRowSize).toList()),
        const SizedBox(height: 8),
        _row(context, cards.skip(firstRowSize).toList()),
      ],
    );
  }

  Widget _row(BuildContext context, List<DayCard> row) => Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (final card in row)
            TodayStatusChip(
              key: ValueKey(card.type),
              type: card.type,
              read: readTypes.contains(card.type),
            ),
        ],
      );
}

/// Один чип статуса — свой тип и `ValueKey(type)`, чтобы тесты находили
/// конкретный чип по типу карточки, а не по надписи на нём.
class TodayStatusChip extends StatelessWidget {
  const TodayStatusChip({super.key, required this.type, required this.read});

  final CardType type;
  final bool read;

  @override
  Widget build(BuildContext context) {
    final style = type.styleFor(Theme.of(context).brightness);
    final colors = AppColorsExtension.of(context);
    return AppPillBadge(
      label: style.shortLabel,
      background: read ? style.tagBackground : Colors.transparent,
      foreground: read ? style.tagForeground : colors.chipUnreadText,
      border: read ? null : Border.all(color: colors.chipUnreadBorder),
      horizontalPadding: 13,
      fontSize: 11.5,
    );
  }
}
