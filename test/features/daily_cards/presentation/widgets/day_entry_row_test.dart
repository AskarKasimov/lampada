import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/day_entry_row.dart';

void main() {
  for (final label in ['ЦИТАТА', 'СОВЕТ', 'ПРИТЧА', 'ЕВАНГЕЛИЕ ДНЯ']) {
    for (final unread in [true, false]) {
      testWidgets('$label: метка внутри заголовка, непрочитано: $unread', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
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

        final dot = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
        );
        if (unread) {
          final dotBounds = tester.getRect(dot);
          final heading = tester.getRect(find.text(label));
          expect(dotBounds.left, 20);
          expect(dotBounds.right, lessThan(heading.left));
          expect(dotBounds.center.dy, heading.center.dy);
        } else {
          expect(dot, findsNothing);
        }
        expect(tester.getTopLeft(find.text(label)).dx, unread ? 33 : 20);
        expect(tester.getTopLeft(find.text('Материал дня')).dx, 20);
        expect(tester.getTopRight(find.text('Материал дня')).dx, 780);
        expect(tester.getRect(find.byType(InkWell)).left, 0);
        expect(tester.getRect(find.byType(InkWell)).right, 800);
      });
    }
  }
}
