import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_colors.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/home_button.dart';

Widget _buildApp(ThemeData theme) => MaterialApp(
      theme: theme,
      home: Scaffold(body: HomeButton(onPressed: () {})),
    );

void main() {
  testWidgets('фон кнопки берётся из темы, а не хардкода', (tester) async {
    await tester.pumpWidget(_buildApp(AppTheme.light));
    await tester.pump();

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(HomeButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, AppColorsExtension.light.homeButtonBackground);
  });

  testWidgets('на тёмной теме фон свой, не тот же цвет, что на светлой',
      (tester) async {
    await tester.pumpWidget(_buildApp(AppTheme.dark));
    await tester.pump();

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(HomeButton),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, AppColorsExtension.dark.homeButtonBackground);
    expect(material.color, isNot(AppColorsExtension.light.homeButtonBackground));
  });

  testWidgets('тап вызывает onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: HomeButton(onPressed: () => tapped = true)),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(HomeButton));
    expect(tapped, isTrue);
  });
}
