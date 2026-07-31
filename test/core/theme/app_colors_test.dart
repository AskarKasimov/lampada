import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_colors.dart';

void main() {
  test('light и dark — разные палитры с ключевыми цветами', () {
    expect(AppColorsExtension.light.background, const Color(0xFFFAF0E3));
    expect(AppColorsExtension.dark.background, const Color(0xFF1E1712));
    expect(AppColorsExtension.light.ink, isNot(AppColorsExtension.dark.ink));
    // Конкретные значения акцента не фиксируем: они подбираются под порог
    // контраста, и это стережёт app_colors_contrast_test.dart. Здесь важно
    // лишь то, что темы не совпадают и акцент тёплый.
    expect(
      AppColorsExtension.light.accent,
      isNot(AppColorsExtension.dark.accent),
    );
    for (final colors in [AppColorsExtension.light, AppColorsExtension.dark]) {
      expect(colors.accent.r, greaterThan(colors.accent.b),
          reason: 'акцент должен остаться тёплым');
    }
  });

  testWidgets(
      'AppColorsExtension.of возвращает light без зарегистрированной темы',
      (tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        capturedContext = context;
        return const SizedBox.shrink();
      }),
    ));

    expect(AppColorsExtension.of(capturedContext), AppColorsExtension.light);
  });
}
