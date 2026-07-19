import 'package:flutter/material.dart';

/// Закруглённая плашка с текстом — плашка типа карточки и чипы статуса
/// на Home различаются только цветами/паддингом/бордером, форма одна.
class AppPillBadge extends StatelessWidget {
  const AppPillBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.border,
    this.horizontalPadding = 14,
    this.fontSize = 12,
    this.letterSpacing,
  });

  final String label;
  final Color background;
  final Color foreground;
  final BoxBorder? border;
  final double horizontalPadding;
  final double fontSize;
  final double? letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
        border: border,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: letterSpacing,
          color: foreground,
        ),
      ),
    );
  }
}
