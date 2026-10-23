import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_colors.dart';
import 'package:lampada/core/theme/app_theme.dart';

void main() {
  test('AppTheme.light регистрирует светлую палитру и светлую яркость', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(
      AppTheme.light.extension<AppColorsExtension>(),
      AppColorsExtension.light,
    );
  });

  test('AppTheme.dark регистрирует тёмную палитру и тёмную яркость', () {
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(
      AppTheme.dark.extension<AppColorsExtension>(),
      AppColorsExtension.dark,
    );
  });

  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets('PT Sans без разрядки Material 3: ${theme.brightness}', (
      tester,
    ) async {
      // Разрядка Material 3 (+0.25…0.5) делает SF рыхлым рядом с Lora.
      // Flutter подмешивает её в Theme.of при локализации темы, поэтому
      // проверяем тему из контекста, а не саму ThemeData.
      late ThemeData resolved;
      late TextStyle inherited;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Material(
            child: Builder(
              builder: (context) {
                resolved = Theme.of(context);
                inherited = DefaultTextStyle.of(context).style;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(inherited.letterSpacing ?? 0, 0);
      // Подписи и интерфейс набраны PT Sans: гуманистический гротеск
      // ближе к Lora, чем системный SF.
      expect(inherited.fontFamily, 'PT Sans');
      expect(resolved.textTheme.labelLarge?.fontFamily, 'PT Sans');
      for (final textTheme in [resolved.textTheme, resolved.primaryTextTheme]) {
        final styles = [
          textTheme.displayLarge,
          textTheme.displayMedium,
          textTheme.displaySmall,
          textTheme.headlineLarge,
          textTheme.headlineMedium,
          textTheme.headlineSmall,
          textTheme.titleLarge,
          textTheme.titleMedium,
          textTheme.titleSmall,
          textTheme.bodyLarge,
          textTheme.bodyMedium,
          textTheme.bodySmall,
          textTheme.labelLarge,
          textTheme.labelMedium,
          textTheme.labelSmall,
        ];
        for (final style in styles) {
          expect(style?.letterSpacing ?? 0, 0, reason: style?.debugLabel);
        }
      }
    });
  }

  testWidgets('serif без курсива: заголовки и чтение одной гарнитурой', (
    tester,
  ) async {
    late TextStyle quote;
    late TextStyle heading;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            quote = AppTheme.quoteStyle(context);
            heading = AppTheme.headingStyle(context, fontSize: 30);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(quote.fontFamily, 'Lora');
    expect(quote.fontStyle, isNot(FontStyle.italic));
    expect(heading.fontFamily, 'Lora');
    expect(heading.fontStyle, isNot(FontStyle.italic));
    expect(heading.fontSize, 30);
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      testWidgets(
        'Единые иконки назад и закрытия: $platform, ${theme.brightness}',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme.copyWith(platform: platform),
              home: const Scaffold(
                body: Row(children: [BackButton(), CloseButton()]),
              ),
            ),
          );
          expect(find.byIcon(CupertinoIcons.arrow_left), findsOneWidget);
          expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
          expect(
            tester.widget<Icon>(find.byIcon(CupertinoIcons.arrow_left)).size,
            22,
          );
        },
      );
    }
  }

  testWidgets('AppTheme.quoteStyle берёт цвет ink активной темы', (
    tester,
  ) async {
    late TextStyle style;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) {
            style = AppTheme.quoteStyle(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(style.color, AppColorsExtension.dark.ink);
  });
}
