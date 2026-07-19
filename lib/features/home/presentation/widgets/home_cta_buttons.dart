import 'package:flutter/material.dart';

import '../../../../core/widgets/app_link_button.dart';
import '../../../../core/widgets/app_primary_button.dart';

/// Сегодня ничего не прочитано — запускает сессию с первой карточки.
class HomeStartButton extends StatelessWidget {
  const HomeStartButton({
    super.key,
    required this.color,
    required this.onPressed,
  });

  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => AppPrimaryButton(
        label: 'Начать',
        color: color,
        onPressed: onPressed,
        horizontalPadding: 44,
      );
}

/// Часть карточек уже прочитана — продолжает с первой непрочитанной.
class HomeContinueButton extends StatelessWidget {
  const HomeContinueButton({
    super.key,
    required this.color,
    required this.onPressed,
  });

  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => AppPrimaryButton(
        label: 'Продолжить',
        color: color,
        onPressed: onPressed,
        horizontalPadding: 44,
      );
}

/// Всё прочитано сегодня — перечитать карточки заново, не трогая прогресс.
class HomeReplayButton extends StatelessWidget {
  const HomeReplayButton({
    super.key,
    required this.color,
    required this.onPressed,
  });

  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => AppLinkButton(
        label: 'Пройти снова',
        color: color,
        onPressed: onPressed,
        fontSize: 12,
      );
}
