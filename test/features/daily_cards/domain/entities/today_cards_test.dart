import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';

const _cards = [
  DayCard(id: 'q', type: CardType.quote, body: 'b', source: 's'),
];

void main() {
  test('без staleDate набор считается свежим', () {
    const today = TodayCards(cards: _cards);

    expect(today.staleDate, isNull);
    expect(today.cards, hasLength(1));
  });

  test('со staleDate набор помечен как кэш за другую дату', () {
    final stale = TodayCards(cards: _cards, staleDate: DateTime(2026, 7, 19));

    expect(stale.staleDate, DateTime(2026, 7, 19));
  });
}
