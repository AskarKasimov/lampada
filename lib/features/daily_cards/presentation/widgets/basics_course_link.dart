import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/day_card.dart';
import '../theme/card_type_style.dart';
import 'basics_hero_block.dart';

/// Тихая точка входа в личный курс на датах, где нет большой карточки курса.
class BasicsCourseLink extends StatelessWidget {
  const BasicsCourseLink({required this.card, required this.onTap, super.key});

  final DayCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final accent = CardType.basics
        .styleFor(Theme.of(context).brightness)
        .accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.school_outlined, size: 17, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      basicsCourseTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: colors.homeSubtitle),
            ],
          ),
        ),
      ),
    );
  }
}
