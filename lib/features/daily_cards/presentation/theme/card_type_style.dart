import 'package:flutter/material.dart';

import '../../domain/entities/day_card.dart';

/// Цветовое кодирование типа карточки: акцент для точки прогресса,
/// цвета плашки-лейбла. Только presentation — domain про цвета не знает.
class CardTypeStyle {
  const CardTypeStyle({
    required this.label,
    required this.shortLabel,
    required this.accent,
    required this.tagBackground,
    required this.tagForeground,
  });

  final String label;

  /// Короткая подпись для чипов статуса на Home.
  final String shortLabel;

  final Color accent;
  final Color tagBackground;
  final Color tagForeground;
}

extension CardTypeStyleX on CardType {
  /// Стиль карточки для текущей яркости темы — у каждого типа свой
  /// набор цветов на светлую и тёмную тему.
  CardTypeStyle styleFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (this) {
      CardType.quote => isDark
          ? const CardTypeStyle(
              label: 'Цитата дня',
              shortLabel: 'Цитата',
              accent: Color(0xFFD99A4A),
              tagBackground: Color(0xFF3D2B14),
              tagForeground: Color(0xFFF4CFA0),
            )
          : const CardTypeStyle(
              label: 'Цитата дня',
              shortLabel: 'Цитата',
              accent: Color(0xFFBA7E2D),
              tagBackground: Color(0xFFF4E1CC),
              tagForeground: Color(0xFF603800),
            ),
      CardType.advice => isDark
          ? const CardTypeStyle(
              label: 'Совет дня',
              shortLabel: 'Совет',
              accent: Color(0xFF7BC17E),
              tagBackground: Color(0xFF1D3320),
              tagForeground: Color(0xFFBEEAC0),
            )
          : const CardTypeStyle(
              label: 'Совет дня',
              shortLabel: 'Совет',
              accent: Color(0xFF5A9F5D),
              tagBackground: Color(0xFFD7EBD7),
              tagForeground: Color(0xFF1E4E22),
            ),
      CardType.basics => isDark
          ? const CardTypeStyle(
              label: 'Основы',
              shortLabel: 'Основы',
              accent: Color(0xFF6BB8E8),
              tagBackground: Color(0xFF17293A),
              tagForeground: Color(0xFFB9E0F7),
            )
          : const CardTypeStyle(
              label: 'Основы',
              shortLabel: 'Основы',
              accent: Color(0xFF3A95CD),
              tagBackground: Color(0xFFD1E8FA),
              tagForeground: Color(0xFF00476D),
            ),
      CardType.reading => isDark
          ? const CardTypeStyle(
              label: 'Чтение',
              shortLabel: 'Чтение',
              accent: Color(0xFFDD8F90),
              tagBackground: Color(0xFF3A2224),
              tagForeground: Color(0xFFF4C3C4),
            )
          : const CardTypeStyle(
              label: 'Чтение',
              shortLabel: 'Чтение',
              accent: Color(0xFFCB6C6D),
              tagBackground: Color(0xFFFBDCDB),
              tagForeground: Color(0xFF6A2B2E),
            ),
      // Замыкает день: не факт из источника, а приглашение подумать самому.
      CardType.question => isDark
          ? const CardTypeStyle(
              label: 'Вопрос дня',
              shortLabel: 'Вопрос',
              accent: Color(0xFFB79EE8),
              tagBackground: Color(0xFF2B2040),
              tagForeground: Color(0xFFDCC9F5),
            )
          : const CardTypeStyle(
              label: 'Вопрос дня',
              shortLabel: 'Вопрос',
              accent: Color(0xFF8E6BC4),
              tagBackground: Color(0xFFE8E0F5),
              tagForeground: Color(0xFF3D2570),
            ),
    };
  }
}
