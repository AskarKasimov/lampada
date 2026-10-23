import 'package:flutter/material.dart';

import '../../../../core/format/russian_date.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import 'home_section_header.dart';
import 'streak_card.dart';
import 'streak_lamp_icon.dart';

/// Шапка главной: строка даты над крупным «Сегодня», без приветствия, и
/// лампада серии, которая открывает шторку «Лампадки». Шапка закреплена над
/// списком, поэтому серия видна и при прокрутке.
///
/// Дата и пост стоят одной строкой одного кегля и цвета над заголовком, а
/// не подписями сбоку: рядом с крупной Lora две мелкие подписи разного
/// цвета выглядели разрозненно.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.date,
    required this.streak,
    required this.onStreakTap,
    this.isFast = false,
    super.key,
  });

  final DateTime date;

  /// Пост относится ко всему дню, поэтому отмечен здесь, а не на плитке.
  final bool isFast;

  /// Текущая серия; null, пока прогресс не загружен.
  final int? streak;

  final VoidCallback onStreakTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final streak = this.streak;
    return Padding(
      padding:
          AppSpacing.of(context).horizontal +
          const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    russianDayMonth(date),
                    if (isFast) 'Постный день',
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.2,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Semantics(
                  header: true,
                  child: Text(
                    'Сегодня',
                    style: AppTheme.headingStyle(
                      context,
                      fontSize: HomeSectionHeader.titleSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (streak != null) ...[
            const SizedBox(width: 8),
            _StreakButton(streak: streak, onTap: onStreakTap),
          ],
        ],
      ),
    );
  }
}

class _StreakButton extends StatelessWidget {
  const _StreakButton({required this.streak, required this.onTap});

  final int streak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Semantics(
      button: true,
      label: 'Лампадка: $streak ${streakDaysLabel(streak)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: ConstrainedBox(
          // Минимальная зона нажатия по HIG.
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreakLampIcon(lit: streak > 0, size: 28),
                const SizedBox(width: 4),
                Text(
                  '$streak',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: streak > 0 ? colors.ink : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
