import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/theme/app_theme.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/home/presentation/widgets/today_status_chips.dart';

DayCard _card(CardType type) =>
    DayCard(id: type.name, type: type, body: 'b', source: 's');

Widget _buildApp(List<DayCard> cards) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: TodayStatusChips(cards: cards, readTypes: const {}),
      ),
    );

void main() {
  testWidgets('5 карточек: три сверху, две снизу — не 4 и одна сиротой',
      (tester) async {
    await tester.pumpWidget(_buildApp([
      _card(CardType.quote),
      _card(CardType.question),
      _card(CardType.advice),
      _card(CardType.basics),
      _card(CardType.reading),
    ]));
    await tester.pump();

    final wraps = tester.widgetList<Wrap>(find.byType(Wrap)).toList();
    expect(wraps, hasLength(2));
    expect(wraps[0].children, hasLength(3));
    expect(wraps[1].children, hasLength(2));

    // «Чтение» — в нижней строке, а не одна в верхней.
    final firstRowY = tester.getTopLeft(find.byWidget(wraps[0])).dy;
    final secondRowY = tester.getTopLeft(find.byWidget(wraps[1])).dy;
    expect(secondRowY, greaterThan(firstRowY));
    expect(
      find.descendant(
        of: find.byWidget(wraps[1]),
        matching: find.byKey(const ValueKey(CardType.reading)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('4 или меньше карточек: одна строка, без деления', (tester) async {
    await tester.pumpWidget(_buildApp([
      _card(CardType.quote),
      _card(CardType.advice),
      _card(CardType.basics),
      _card(CardType.reading),
    ]));
    await tester.pump();

    expect(find.byType(Wrap), findsOneWidget);
  });
}
