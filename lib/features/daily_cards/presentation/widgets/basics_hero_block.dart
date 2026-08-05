import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/day_card.dart';
import '../theme/card_type_style.dart';

const basicsCourseTitle = 'Основы веры';

/// Личная тема курса «Основы»: идёт последовательно и не зависит от даты
/// открытого календарного дня.
class BasicsHeroBlock extends StatelessWidget {
  const BasicsHeroBlock({
    super.key,
    required this.card,
    required this.isRead,
    required this.onTap,
  });

  final DayCard card;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = CardType.basics
        .styleFor(Theme.of(context).brightness)
        .accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: accent.withValues(alpha: isDark ? 0.20 : 0.13),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? 0.42 : 0.34),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school_outlined, size: 17, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    'ПОСЛЕДОВАТЕЛЬНЫЙ КУРС',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.9,
                      color: accent,
                    ),
                  ),
                  const Spacer(),
                  if (isRead) Icon(Icons.check_circle, size: 17, color: accent),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                basicsCourseTitle,
                style: AppTheme.quoteStyle(
                  context,
                ).copyWith(fontSize: 26, height: 1.2),
              ),
              const SizedBox(height: 8),
              Text(
                'Следующая тема откроется после прочтения этой',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
