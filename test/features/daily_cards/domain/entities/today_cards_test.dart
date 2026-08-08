import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/features/daily_cards/domain/entities/day_card.dart';
import 'package:lampada/features/daily_cards/domain/entities/today_cards.dart';

const _cards = [DayCard(id: 'q', type: CardType.quote, body: 'b', source: 's')];

void main() {
  test('хранит карточки запрошенного дня', () {
    const today = TodayCards(cards: _cards);

    expect(today.cards, hasLength(1));
  });
}
