import 'package:flutter/material.dart';

/// Основная CTA-кнопка (FilledButton, stadium-форма) — общий стиль для
/// «Дальше»/«Готово» на карточках и «Начать»/«Продолжить» на Home.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.horizontalPadding = 40,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
