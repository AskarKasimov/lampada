// lib/features/home/presentation/widgets/home_cta_buttons.dart
import 'package:flutter/material.dart';

/// Общий стиль главной CTA Home — различаются только виджеты-варианты
/// ниже, каждый со своим типом для тестов (`find.byType`).
class _HomeCtaStyle extends StatelessWidget {
  const _HomeCtaStyle({
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
        padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

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
  Widget build(BuildContext context) =>
      _HomeCtaStyle(label: 'Начать', color: color, onPressed: onPressed);
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
  Widget build(BuildContext context) =>
      _HomeCtaStyle(label: 'Продолжить', color: color, onPressed: onPressed);
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
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: color),
      child: Text(
        'Пройти снова',
        style: TextStyle(
          fontSize: 12,
          decoration: TextDecoration.underline,
          decorationColor: color,
        ),
      ),
    );
  }
}
