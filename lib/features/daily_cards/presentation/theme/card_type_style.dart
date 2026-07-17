import 'package:flutter/material.dart';

import '../../domain/entities/day_card.dart';

/// Цветовое кодирование типа карточки: акцент для точки прогресса,
/// цвета плашки-лейбла над текстом карточки. Только presentation —
/// domain про цвета ничего не знает.
class CardTypeStyle {
  const CardTypeStyle({
    required this.label,
    required this.accent,
    required this.tagBackground,
    required this.tagForeground,
  });

  final String label;
  final Color accent;
  final Color tagBackground;
  final Color tagForeground;
}

extension CardTypeStyleX on CardType {
  CardTypeStyle get style => switch (this) {
        CardType.quote => const CardTypeStyle(
            label: 'Цитата дня',
            accent: Color(0xFFBA7E2D),
            tagBackground: Color(0xFFF4E1CC),
            tagForeground: Color(0xFF603800),
          ),
        CardType.advice => const CardTypeStyle(
            label: 'Совет дня',
            accent: Color(0xFF5A9F5D),
            tagBackground: Color(0xFFD7EBD7),
            tagForeground: Color(0xFF1E4E22),
          ),
        CardType.basics => const CardTypeStyle(
            label: 'Основы',
            accent: Color(0xFF3A95CD),
            tagBackground: Color(0xFFD1E8FA),
            tagForeground: Color(0xFF00476D),
          ),
        CardType.reading => const CardTypeStyle(
            label: 'Чтение',
            accent: Color(0xFFCB6C6D),
            tagBackground: Color(0xFFFBDCDB),
            tagForeground: Color(0xFF6A2B2E),
          ),
      };
}
