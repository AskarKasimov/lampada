// lib/features/daily_cards/presentation/widgets/session_done_view.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'streak_flame.dart';
import 'streak_label.dart';

/// Экран завершения дня: порция получена.
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
          'Огонёк на сегодня зажжён\nУвидимся завтра',
          textAlign: TextAlign.center,
          style:
              AppTheme.quoteStyle(context).copyWith(fontSize: 22, height: 1.55),
        ),
        const SizedBox(height: 20),
        StreakLabel(
          days: streakDays,
          style: TextStyle(fontSize: 14, color: colors.textSecondary),
        ),
        const SizedBox(height: 10),
        SessionDoneHomeButton(color: colors.link, onPressed: onHome),
      ],
    );
  }
}

/// «На главный экран» на done-экране — свой тип, чтобы тесты искали
/// по структуре, а не по тексту кнопки.
class SessionDoneHomeButton extends StatelessWidget {
  const SessionDoneHomeButton({
    super.key,
    required this.color,
    required this.onPressed,
  });

  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: color),
      child: Text(
        'На главный экран',
        style: TextStyle(
          fontSize: 13,
          decoration: TextDecoration.underline,
          decorationColor: color,
        ),
      ),
    );
  }
}
