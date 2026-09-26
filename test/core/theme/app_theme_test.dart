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
