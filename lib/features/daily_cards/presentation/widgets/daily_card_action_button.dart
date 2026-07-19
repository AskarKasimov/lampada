import 'package:flutter/material.dart';

import '../../../../core/widgets/app_primary_button.dart';

/// Не последняя карточка дня — переход к следующей.
class DailyCardNextButton extends StatelessWidget {
  const DailyCardNextButton({
    super.key,
    required this.color,
    required this.onPressed,
  });

  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      AppPrimaryButton(label: 'Дальше', color: color, onPressed: onPressed);
}

/// Последняя карточка дня — завершает сессию.
class DailyCardDoneButton extends StatelessWidget {
  const DailyCardDoneButton({
    super.key,
    required this.color,
    required this.onPressed,
  });

  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      AppPrimaryButton(label: 'Готово', color: color, onPressed: onPressed);
}
