import 'package:flutter/material.dart';

/// Второстепенная текстовая кнопка (подчёркнутая) — «На главный экран»,
/// «Пройти снова», «Повторить» после ошибки загрузки.
class AppLinkButton extends StatelessWidget {
  const AppLinkButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.fontSize = 13,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: color),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          decoration: TextDecoration.underline,
          decorationColor: color,
        ),
      ),
    );
  }
}
