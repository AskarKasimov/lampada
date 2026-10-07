import 'package:flutter/material.dart';

import '../../domain/entities/day_card.dart';
import 'home_tile.dart';
import 'orthodox_cross.dart';
import 'read_status_checks.dart';

/// Крупный вход в дневные материалы с отметкой их общего прочтения.
class DayWisdomTile extends StatelessWidget {
  const DayWisdomTile({
    required this.isUnread,
    required this.onTap,
    this.isLoading = false,
    super.key,
  });

  final bool isUnread;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => HomeTile(
    title: 'Мудрость дня',
    type: CardType.quote,
    illustration: (color) => OrthodoxCross(color: color),
    semanticsLabel: isLoading
        ? 'Мудрость дня. Загружаем материалы дня'
        : 'Мудрость дня${isUnread ? '' : '. Прочитано'}',
    onTap: isLoading ? null : onTap,
    status: isLoading
        ? const SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : ReadStatusChecks(isUnread: isUnread),
  );
}
