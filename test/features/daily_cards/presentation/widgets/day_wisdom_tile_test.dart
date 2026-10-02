import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/day_wisdom_tile.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'подзаголовок под названием открывает день при масштабе $scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var opened = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: DayWisdomTile(
                  isUnread: true,
                  onTap: () => opened = true,
                ),
              ),
            ),
          ),
        );
        final title = find.text('Мудрость дня');
        final subtitle = find.text('Цитата, совет, притча и Евангелие');
        expect(subtitle, findsOneWidget);
        expect(
          tester.getRect(subtitle).top,
          greaterThan(tester.getRect(title).bottom),
        );
        expect(tester.getRect(subtitle).left, tester.getRect(title).left);
        expect(tester.getRect(subtitle).right, lessThanOrEqualTo(320));
        expect(tester.takeException(), isNull);
        await tester.tap(subtitle);
        expect(opened, isTrue);
      },
    );
  }
}
