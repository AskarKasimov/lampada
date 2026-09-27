import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_colors.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/day_entry_row.dart';

void main() {
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    for (final label in ['ЦИТАТА', 'СОВЕТ', 'ПРИТЧА', 'ЕВАНГЕЛИЕ ДНЯ']) {
      for (final unread in [true, false]) {
        testWidgets('$label: метка внутри заголовка, непрочитано: $unread', (
          tester,
        ) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Scaffold(
                body: DayEntryRow(
                  label: label,
                  text: 'Материал дня',
                  isUnread: unread,
                  onTap: () {},
                ),
              ),
            ),
          );

          final checks = find.byIcon(CupertinoIcons.checkmark_alt);
          expect(checks, findsNWidgets(2));
          final colors = AppColorsExtension.of(
            tester.element(find.byType(DayEntryRow)),
          );
          for (final check in tester.widgetList<Icon>(checks)) {
            expect(
              check.color,
              unread
                  ? colors.textTertiary.withValues(alpha: 0.4)
                  : colors.accent,
            );
            expect(check.size, 14);
          }
          final checkBounds = checks
              .evaluate()
              .map((element) => tester.getRect(find.byWidget(element.widget)))
              .toList();
          expect(checkBounds[1].left - checkBounds[0].left, 5);
          expect(checkBounds[0].right - checkBounds[1].left, 9);
          final heading = tester.getRect(find.text(label));
          for (final check in checks.evaluate()) {
            final bounds = tester.getRect(find.byWidget(check.widget));
            expect(bounds.left, greaterThanOrEqualTo(20));
            expect(bounds.right, lessThan(heading.left));
            expect(bounds.center.dy, heading.center.dy);
          }
          expect(tester.getTopLeft(find.text(label)).dx, 46);
          expect(tester.getTopLeft(find.text('Материал дня')).dx, 20);
          expect(tester.getTopRight(find.text('Материал дня')).dx, 780);
          expect(tester.getRect(find.byType(InkWell)).left, 0);
          expect(tester.getRect(find.byType(InkWell)).right, 800);
        });
      }
    }
  }
}
