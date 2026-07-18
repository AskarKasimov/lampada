// lib/features/daily_cards/presentation/widgets/session_done_view.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'streak_flame.dart';

/// Экран завершения дня: порция получена, можно остановиться.
class SessionDoneView extends StatelessWidget {
  const SessionDoneView({
    super.key,
    required this.streakDays,
    required this.onHome,
  });

  final int streakDays;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const StreakFlame(size: 14),
        const SizedBox(height: 20),
        Text(
          'Мысль дня получена.\nМожно остановиться — или вернуться завтра.',
          textAlign: TextAlign.center,
          style:
              AppTheme.quoteStyle(context).copyWith(fontSize: 22, height: 1.55),
        ),
        const SizedBox(height: 20),
        Text(
          'Текущая серия $streakDays дней',
          style: TextStyle(fontSize: 14, color: colors.textSecondary),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onHome,
          style: TextButton.styleFrom(foregroundColor: colors.link),
          child: Text(
            'На главный экран',
            style: TextStyle(
              fontSize: 13,
              decoration: TextDecoration.underline,
              decorationColor: colors.link,
            ),
          ),
        ),
      ],
    );
  }
}
