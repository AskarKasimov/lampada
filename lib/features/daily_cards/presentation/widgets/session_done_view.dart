import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_link_button.dart';
import '../../../../core/widgets/streak_flame.dart';

/// Экран завершения дня: порция получена.
///
/// Огонёк здесь бессловесный. Числа «текущая серия N дней» тут больше нет:
/// FR-019 селит «Лампадку» только в календарь «Дни», а FR-020 прямо запрещает
/// показывать её давящим счётчиком.
class SessionDoneView extends StatelessWidget {
  const SessionDoneView({super.key, required this.onDone});

  final VoidCallback onDone;

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
        const SizedBox(height: 14),
        Text(
          'Завтра — новый день и новые карточки',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        const SizedBox(height: 10),
        SessionDoneButton(onPressed: onDone),
      ],
    );
  }
}

/// «Готово» на экране завершения — свой тип, чтобы тесты искали
/// по структуре, а не по тексту кнопки.
///
/// Раньше здесь было «Пройти снова», и это читалось нелогично: чтобы
/// перечитать одну карточку, приходилось запускать весь день заново.
/// Теперь возврат ведёт к блокам дня, где любая часть открывается напрямую.
class SessionDoneButton extends StatelessWidget {
  const SessionDoneButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => AppLinkButton(
        label: 'Пройти снова',
        color: AppColorsExtension.of(context).link,
        fontSize: 12,
        onPressed: onPressed,
      );
}
