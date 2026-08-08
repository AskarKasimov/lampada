import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/presentation/widgets/day_card_block.dart';

void main() {
  testWidgets('скрывает статус прочтения, когда он недоступен', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DayCardBlock(
            card: const DayCard(
              id: 'quote',
              type: CardType.quote,
              body: 'Текст карточки',
              source: 'Источник',
            ),
            isRead: false,
            showReadStatus: false,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byIcon(Icons.circle_outlined), findsNothing);
  });
}
