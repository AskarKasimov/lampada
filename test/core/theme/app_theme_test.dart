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

  testWidgets('тень карточек главной мягкая и широкая, как у iOS-виджетов', (
    tester,
  ) async {
    late List<BoxShadow> light;
    late List<BoxShadow> dark;
    Widget capture(ThemeData theme, void Function(List<BoxShadow>) save) =>
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              save(AppTheme.cardShadow(context));
              return const SizedBox();
            },
          ),
        );
    await tester.pumpWidget(capture(AppTheme.light, (s) => light = s));
    await tester.pumpWidget(capture(AppTheme.dark, (s) => dark = s));

    for (final shadows in [light, dark]) {
      // Широкое рассеянное облако вокруг всей карточки, а не короткая
      // полоска под нижним краем.
      final ambient = shadows.reduce(
        (a, b) => a.blurRadius >= b.blurRadius ? a : b,
      );
      expect(ambient.blurRadius, greaterThanOrEqualTo(28));
      expect(ambient.offset.dx, 0);
      expect(ambient.offset.dy, lessThan(ambient.blurRadius / 2));
    }
    // В светлой теме облако заметное, но мягкое: карточка явно отрывается
    // от фона и не темнеет по краям.
    final ambient = light.reduce(
      (a, b) => a.blurRadius >= b.blurRadius ? a : b,
    );
    expect(ambient.color.a, inInclusiveRange(0.10, 0.16));
  });
}
