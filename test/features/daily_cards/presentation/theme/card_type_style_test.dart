import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/presentation/theme/card_type_style.dart';

void main() {
  test(
      'у каждого CardType — свой акцентный цвет и свои цвета плашки (light)',
      () {
    final styles =
        CardType.values.map((t) => t.styleFor(Brightness.light)).toList();

    expect(styles.map((s) => s.accent).toSet().length, CardType.values.length);
    expect(
      styles.map((s) => s.tagBackground).toSet().length,
      CardType.values.length,
    );
  });

  test('у каждого CardType — свой акцентный цвет и свои цвета плашки (dark)',
      () {
    final styles =
        CardType.values.map((t) => t.styleFor(Brightness.dark)).toList();

    expect(styles.map((s) => s.accent).toSet().length, CardType.values.length);
    expect(
      styles.map((s) => s.tagBackground).toSet().length,
      CardType.values.length,
    );
  });

  test('CardType.quote light соответствует расчётной палитре из дизайна', () {
    final style = CardType.quote.styleFor(Brightness.light);

    expect(style.accent, const Color(0xFFBA7E2D));
    expect(style.tagBackground, const Color(0xFFF4E1CC));
    expect(style.tagForeground, const Color(0xFF603800));
  });

  test('CardType.quote dark соответствует расчётной палитре из дизайна', () {
    final style = CardType.quote.styleFor(Brightness.dark);

    expect(style.accent, const Color(0xFFD99A4A));
    expect(style.tagBackground, const Color(0xFF3D2B14));
    expect(style.tagForeground, const Color(0xFFF4CFA0));
  });
}
