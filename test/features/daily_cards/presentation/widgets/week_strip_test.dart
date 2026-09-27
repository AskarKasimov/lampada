import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/week_strip.dart';

void main() {
  final today = DateTime(2026, 9, 27);
  late List<DateTime> selections;

  Widget app(DateTime selected) => MaterialApp(
    home: Scaffold(
      body: WeekStrip(
        selected: selected,
        today: today,
        litDays: const {},
        onSelect: selections.add,
      ),
    ),
  );

  setUp(() => selections = []);

  testWidgets('страницы листаются через границу месяца без выбора дня', (
    tester,
  ) async {
    await tester.pumpWidget(app(today));
    await tester.drag(find.text('24'), const Offset(-650, 0));
    await tester.pumpAndSettle();
    expect(find.text('Октябрь 2026'), findsOneWidget);
    expect(selections, isEmpty);
    await tester.tap(find.text('1'));
    expect(selections, [DateTime(2026, 10, 1)]);
    await tester.drag(find.text('1'), const Offset(650, 0));
    await tester.pumpAndSettle();
    expect(find.text('27'), findsOneWidget);
  });

  testWidgets('свайп полоски показывает предыдущую неделю', (tester) async {
    await tester.pumpWidget(app(today));
    await tester.drag(find.text('24'), const Offset(650, 0));
    await tester.pumpAndSettle();
    expect(find.text('14'), findsOneWidget);
    expect(selections, isEmpty);
    await tester.tap(find.text('14'));
    expect(selections, [DateTime(2026, 9, 14)]);
  });

  testWidgets('внешний выбор дня возвращает полоску к его неделе', (
    tester,
  ) async {
    await tester.pumpWidget(app(today));
    await tester.drag(find.text('24'), const Offset(-650, 0));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(DateTime(2026, 9, 22)));
    expect(find.text('22'), findsOneWidget);
    expect(find.text('Вернуться'), findsOneWidget);
    await tester.tap(find.text('Вернуться'));
    expect(selections, [today]);
    await tester.pumpAndSettle();
    expect(find.text('27'), findsOneWidget);
  });

  testWidgets('месяц слева, Вернуться справа, недельные стрелки отсутствуют', (
    tester,
  ) async {
    await tester.pumpWidget(app(DateTime(2026, 9, 22)));
    expect(find.byTooltip('Предыдущая неделя'), findsNothing);
    expect(find.byTooltip('Следующая неделя'), findsNothing);
    expect(tester.getRect(find.text('Сентябрь 2026')).left, lessThan(32));
    expect(tester.getRect(find.text('Вернуться')).right, greaterThan(768));
  });

  testWidgets('при перетаскивании неделя движется вместе с пальцем', (
    tester,
  ) async {
    await tester.pumpWidget(app(today));
    final start = tester.getTopLeft(find.text('24')).dx;
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('24')),
    );
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();
    expect(tester.getTopLeft(find.text('24')).dx, lessThan(start - 50));
    expect(selections, isEmpty);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('дни недели движутся вместе с датами', (tester) async {
    await tester.pumpWidget(app(today));
    final weekdayPosition = tester.getTopLeft(find.text('чт'));
    final datePosition = tester.getTopLeft(find.text('24'));
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('24')),
    );
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();
    final weekdayShift =
        tester.getTopLeft(find.text('чт').first).dx - weekdayPosition.dx;
    final dateShift = tester.getTopLeft(find.text('24')).dx - datePosition.dx;
    expect(weekdayShift, lessThan(-50));
    expect(weekdayShift, closeTo(dateShift, 0.01));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('месяц открывает панель для выбора далёкой даты', (tester) async {
    await tester.pumpWidget(app(today));
    await tester.tap(find.text('Сентябрь 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Предыдущий месяц'));
    await tester.pumpAndSettle();
    expect(find.text('Август 2026'), findsOneWidget);
    expect(selections, isEmpty);
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    expect(selections, [DateTime(2026, 8, 5)]);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('в панели нет Сегодня, закрытие не меняет дату', (tester) async {
    await tester.pumpWidget(app(DateTime(2026, 8, 5)));
    await tester.tap(find.text('Август 2026'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Сегодня'),
      ),
      findsNothing,
    );
    Navigator.of(tester.element(find.text('Август 2026').last)).pop();
    await tester.pumpAndSettle();
    expect(selections, isEmpty);
  });

  testWidgets('панель и строки не прыгают между месяцами с 4, 5 и 6 неделями', (
    tester,
  ) async {
    await tester.pumpWidget(app(DateTime(2021, 2, 15)));
    await tester.tap(find.text('Февраль 2021'));
    await tester.pumpAndSettle();
    final sheetRect = tester.getRect(find.byType(BottomSheet));
    final weekdays = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text('пн'),
    );
    final weekdayTop = tester.getTopLeft(weekdays).dy;
    final firstDay = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text('1'),
    );
    final firstDayTop = tester.getTopLeft(firstDay).dy;
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('Следующий месяц'));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(BottomSheet)), sheetRect);
      expect(tester.getTopLeft(weekdays).dy, weekdayTop);
      expect(tester.getTopLeft(firstDay).dy, firstDayTop);
    }
    expect(find.text('Май 2021'), findsOneWidget);
    final lastDay = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text('31'),
    );
    expect(sheetRect.bottom - tester.getBottomLeft(lastDay).dy, lessThan(44));
  });

  testWidgets('месяц движется за пальцем и выбирает дату показанной страницы', (
    tester,
  ) async {
    await tester.pumpWidget(app(today));
    await tester.tap(find.text('Сентябрь 2026'));
    await tester.pumpAndSettle();
    final day = find.descendant(
      of: find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            (widget.properties.label ?? '').startsWith('15 Сентябрь 2026,'),
      ),
      matching: find.text('15'),
    );
    final original = tester.getTopLeft(day).dx;
    final gesture = await tester.startGesture(tester.getCenter(day));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();
    expect(tester.getTopLeft(day.first).dx, greaterThan(original + 50));
    await gesture.moveBy(const Offset(500, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Август 2026'), findsOneWidget);
    expect(selections, isEmpty);
    await tester.tap(
      find.descendant(of: find.byType(BottomSheet), matching: find.text('5')),
    );
    await tester.pumpAndSettle();
    expect(selections, [DateTime(2026, 8, 5)]);
  });
}
