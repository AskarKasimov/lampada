import 'package:flutter/material.dart';

/// Общий стиль кнопки под карточкой — различаются только виджеты-варианты
/// ниже, каждый со своим типом для тестов (`find.byType`).
class _DailyCardActionStyle extends StatelessWidget {
  const _DailyCardActionStyle({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

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
      _DailyCardActionStyle(label: 'Дальше', color: color, onPressed: onPressed);
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
      _DailyCardActionStyle(label: 'Готово', color: color, onPressed: onPressed);
}
