import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/day_card.dart';
import '../theme/card_type_style.dart';

/// Одна карточка дня: плашка-тип, курсивная мысль, источник.
class CardContent extends StatelessWidget {
  const CardContent({super.key, required this.card});

  final DayCard card;

  @override
  Widget build(BuildContext context) {
    final style = card.type.style;

    return Column(
      key: ValueKey(card.id),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: style.tagBackground,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            style.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: style.tagForeground,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(card.body, style: AppTheme.quoteStyle, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(
          '— ${card.source}',
          style: const TextStyle(
            fontSize: 13,
            letterSpacing: 0.2,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
