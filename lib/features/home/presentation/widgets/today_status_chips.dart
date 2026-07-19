// lib/features/home/presentation/widgets/today_status_chips.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final card in cards)
          TodayStatusChip(
            key: ValueKey(card.type),
            type: card.type,
            read: readTypes.contains(card.type),
          ),
      ],
    );
  }
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: read ? style.tagBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(100),
        border: read ? null : Border.all(color: colors.chipUnreadBorder),
      ),
      child: Text(
        style.shortLabel,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: read ? style.tagForeground : colors.chipUnreadText,
        ),
      ),
    );
  }
}
