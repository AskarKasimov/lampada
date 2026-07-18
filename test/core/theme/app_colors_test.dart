import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_colors.dart';

void main() {
  test('light и dark — разные палитры с ключевыми цветами', () {
    expect(AppColorsExtension.light.background, const Color(0xFFFAF0E3));
    expect(AppColorsExtension.dark.background, const Color(0xFF1E1712));
    expect(AppColorsExtension.light.ink, isNot(AppColorsExtension.dark.ink));
    expect(AppColorsExtension.light.accent, const Color(0xFFBE7C1C));
    expect(AppColorsExtension.dark.accent, const Color(0xFFE0983A));
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
