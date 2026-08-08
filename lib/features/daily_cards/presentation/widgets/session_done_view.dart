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
  const SessionDoneView({this.onRead, super.key});

  final VoidCallback? onRead;

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
          style: AppTheme.quoteStyle(
            context,
          ).copyWith(fontSize: 22, height: 1.55),
        ),
        const SizedBox(height: 14),
        Text(
          'Завтра — новый день и новые карточки',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        if (onRead != null) ...[
          const SizedBox(height: 10),
          AppLinkButton(
            label: 'Читать Евангелие',
            color: colors.link,
            fontSize: 13,
            onPressed: onRead!,
          ),
        ],
      ],
    );
  }
}
