import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/presentation/theme/card_type_style.dart';

void main() {
  test('у каждого CardType — свой акцентный цвет и свои цвета плашки', () {
    final styles = CardType.values.map((t) => t.style).toList();

    expect(styles.map((s) => s.accent).toSet().length, CardType.values.length);
    expect(
      styles.map((s) => s.tagBackground).toSet().length,
      CardType.values.length,
    );
  });

  test('CardType.quote соответствует расчётной палитре из дизайна', () {
    final style = CardType.quote.style;

    expect(style.accent, const Color(0xFFBA7E2D));
    expect(style.tagBackground, const Color(0xFFF4E1CC));
    expect(style.tagForeground, const Color(0xFF603800));
  });
}
