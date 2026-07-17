import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'streak_flame.dart';

/// Экран завершения сессии: сегодняшняя порция получена, можно остановиться.
class SessionDoneView extends StatelessWidget {
  const SessionDoneView({
    super.key,
    required this.streakDays,
    required this.onRestart,
  });

  final int streakDays;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const StreakFlame(size: 14),
        const SizedBox(height: 20),
        Text(
          'Мысль дня получена.\nМожно остановиться — или вернуться завтра.',
          textAlign: TextAlign.center,
          style: AppTheme.quoteStyle.copyWith(fontSize: 22, height: 1.55),
        ),
        const SizedBox(height: 20),
        Text(
          'Лампадка горит $streakDays дней',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onRestart,
          style: TextButton.styleFrom(foregroundColor: AppColors.textTertiary),
          child: const Text(
            'Пройти сначала',
            style: TextStyle(
              fontSize: 13,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
