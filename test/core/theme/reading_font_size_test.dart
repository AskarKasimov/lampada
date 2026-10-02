import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/reading_font_size.dart';

void main() {
  testWidgets('измерение учитывает переносы системного жирного текста', (
    tester,
  ) async {
    // Шрифты из Flutter SDK позволяют проверить реальные переносы:
    // тестовый Ahem имеет одинаковую ширину обычного и жирного начертания.
    final fontRoot =
        '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
    await tester.runAsync(() async {
      final loader = FontLoader('Roboto');
      for (final name in ['Roboto-Regular.ttf', 'Roboto-Bold.ttf']) {
        loader.addFont(
          File('$fontRoot/$name').readAsBytes().then(
            (bytes) => ByteData.sublistView(Uint8List.fromList(bytes)),
          ),
        );
      }
      await loader.load();
    });
    const text = '— Тестовый источник';
    const style = TextStyle(
      fontFamily: 'Roboto',
      fontSize: 13,
      letterSpacing: 0.2,
    );
    const width = 137.0;
    late double measured;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(boldText: true),
          child: Scaffold(
            body: Builder(
              builder: (context) {
                measured = readingTextHeight(
                  context: context,
                  text: text,
                  style: style,
                  maxWidth: width,
                );
                return SizedBox(
                  width: width,
                  child: Text(text, style: style),
                );
              },
            ),
          ),
        ),
      ),
    );
    expect(
      measured,
      closeTo(tester.getSize(find.text(text)).height, 0.01),
      reason: 'Ширина $width',
    );
  });
}
