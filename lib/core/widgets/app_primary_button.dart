import 'package:flutter/material.dart';

/// Основная CTA-кнопка: FilledButton в форме скруглённого прямоугольника.
/// Общий стиль для «Готово», «Напоминать» и входа в приложение. Капсула
/// здесь не используется: широкая кнопка в ней выглядела надутой.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.label,
    required this.color,
    required this.onPressed,
    super.key,
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
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 16,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
